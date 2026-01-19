#!/usr/bin/env python3
import os
import json
import re
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Dict, List
from xml.etree import ElementTree as ET
import time
import threading


class TranslationWorker:
    def __init__(self, config: dict, max_retries: int = 2):
        self.config = config
        self.max_retries = max_retries

    def translate_batch(self, strings_list: List[str], target_language: str,
                        source_file: str = "") -> List[Dict[str, str]]:
        if not strings_list:
            return []

        prompt = self._build_translation_prompt(strings_list, target_language, source_file)

        for attempt in range(self.max_retries):
            try:
                response_text = self._call_llm_api(prompt)
                results = self._parse_translation_response(response_text, strings_list)

                if len(results) == len(strings_list):
                    return results
                else:
                    print(f"  Warning: Result count mismatch")
                    print(f"    Expected {len(strings_list)}, got {len(results)}")
                    print(f"    Sample result: {results[0] if results else 'none'}")

            except requests.exceptions.RequestException as e:
                if attempt < self.max_retries - 1:
                    print(f"  Network error, retrying {attempt + 1}/{self.max_retries}: {str(e)}")
                    time.sleep(2 ** attempt)
                else:
                    print(f"  Translation failed, using original: {str(e)}")
            except Exception as e:
                print(f"  Translation error: {str(e)}")

        return [{'source': s, 'translation': s} for s in strings_list]

    def _build_translation_prompt(self, strings_list: List[str], target_language: str,
                                   source_file: str) -> str:
        prompt = f"""Translate the following strings to {target_language} language.
Source file: {source_file if source_file else 'Unknown'}

String list:
"""

        for i, string in enumerate(strings_list, 1):
            prompt += f"\n{i}. {string}\n"

        example = [{"source": strings_list[0], "translation": "..."}] if strings_list else []
        prompt += f"""

Return the results strictly in the following JSON format, do not add any other text:
{json.dumps(example, ensure_ascii=False, indent=2)}

Important notes:
- Maintain accuracy and terminology consistency
- Ensure correct JSON format
- Do not add explanations or other content outside JSON
"""
        return prompt

    def _call_llm_api(self, prompt: str) -> str:
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f"Bearer {self.config['api_key']}"
        }

        data = {
            'model': self.config.get('model', 'qwen3-coder-flash'),
            'messages': [
                {'role': 'user', 'content': prompt}
            ],
            'temperature': self.config.get('temperature', 0.3),
            'max_tokens': 4000
        }

        response = requests.post(
            self.config['api_url'],
            headers=headers,
            json=data,
            timeout=60
        )

        if response.status_code == 200:
            result = response.json()
            return result['choices'][0]['message']['content'].strip()
        else:
            print(f"  API Response: {response.text}")
            raise Exception(f"API call failed: {response.status_code} - {response.text}")

    def _parse_translation_response(self, response_text: str,
                                     original_strings: List[str]) -> List[Dict[str, str]]:
        try:
            results = json.loads(response_text)
            if isinstance(results, list) and all('source' in r and 'translation' in r for r in results):
                return results
        except json.JSONDecodeError:
            pass

        json_match = re.search(r'\[.*\]', response_text, re.DOTALL)
        if json_match:
            try:
                results = json.loads(json_match.group(0))
                if isinstance(results, list) and all('source' in r and 'translation' in r for r in results):
                    return results
            except json.JSONDecodeError:
                pass

        print("  Warning: Unable to parse translation response")
        print(f"  Response: {response_text[:500]}")
        return [{'source': s, 'translation': s} for s in original_strings]


class TranslationBatch:
    def __init__(self, items: List[Dict], target_language: str, source_file: str):
        self.items = items
        self.target_language = target_language
        self.source_file = source_file


class QtTranslationAssistant:
    def __init__(self, config_path: str = "qt_translation_config.json",
                 batch_size: int = 20, max_workers: int = 3):
        self.config = self.load_config(config_path)
        self.batch_size = batch_size
        self.max_workers = max_workers
        self.translator = TranslationWorker(self.config)
        self.lock = threading.Lock()

    def load_config(self, config_path: str) -> dict:
        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Config file not found: {config_path}")
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)

    def find_unfinished_translations(self, ts_file_path: str) -> List[Dict]:
        try:
            with open(ts_file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            ts_match = re.search(r'(<!DOCTYPE[^>]*>\s*)?<TS[^>]*>.*</TS>', content, re.DOTALL)
            if ts_match:
                content = ts_match.group(0)

            content = content.replace(' encoding="UTF-8"', '')

            import io
            tree = ET.parse(io.StringIO(content))
            root = tree.getroot()

            results = []
            for context in root.findall('context'):
                context_name = context.find('name').text if context.find('name') is not None else 'Unknown'

                for message in context.findall('message'):
                    translation_elem = message.find('translation')
                    if translation_elem is not None and translation_elem.get('type') == 'unfinished':
                        source_elem = message.find('source')
                        if source_elem is not None:
                            results.append({
                                'source': source_elem.text or '',
                                'translation': '',
                                'context': context_name
                            })

            return results
        except Exception as e:
            print(f"  Parse failed {ts_file_path}: {str(e)}")
            return []

    def get_language_from_filename(self, filename: str) -> str:
        name = Path(filename).stem
        if '_' in name:
            parts = name.split('_')
            if len(parts) >= 2:
                return '_'.join(parts[1:])
        return 'unknown'

    def translate_single_file(self, ts_file_path: str):
        print(f"\nProcessing: {ts_file_path}")

        unfinished_items = self.find_unfinished_translations(ts_file_path)

        if not unfinished_items:
            print("  No unfinished translations found")
            return

        print(f"  Found {len(unfinished_items)} unfinished translations")

        language_code = self.get_language_from_filename(os.path.basename(ts_file_path))
        print(f"  Target language: {language_code}")

        if language_code == 'unknown':
            print("  English source file, using original text...")
            translation_results = []
            for item in unfinished_items:
                translation_results.append({'source': item['source'], 'translation': item['source']})
            self.write_translations_back(ts_file_path, translation_results)
            return

        batches = self._create_batches(unfinished_items, ts_file_path, language_code)
        translation_results = self._translate_batches_parallel(batches)
        self.write_translations_back(ts_file_path, translation_results)
        print(f"  Translation complete: {len(translation_results)} strings")

    def _create_batches(self, items: List[Dict], source_file: str,
                        target_language: str) -> List[TranslationBatch]:
        batches = []
        for i in range(0, len(items), self.batch_size):
            batch_items = items[i:i + self.batch_size]
            batch = TranslationBatch(batch_items, target_language, source_file)
            batches.append(batch)
        return batches

    def _translate_batches_parallel(self, batches: List[TranslationBatch]) -> List[Dict]:
        all_results = []
        total_batches = len(batches)

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            future_to_batch = {
                executor.submit(self._translate_single_batch, batch): batch
                for batch in batches
            }

            for i, future in enumerate(as_completed(future_to_batch), 1):
                batch = future_to_batch[future]
                try:
                    results = future.result()
                    all_results.extend(results)
                    print(f"  Batch progress: {i}/{total_batches} complete")
                except Exception as e:
                    print(f"  Batch translation failed: {str(e)}")
                    fallback_results = [
                        {'source': item['source'], 'translation': item['source']}
                        for item in batch.items
                    ]
                    all_results.extend(fallback_results)

        return all_results

    def _translate_single_batch(self, batch: TranslationBatch) -> List[Dict]:
        strings_list = [item['source'] for item in batch.items]
        results = self.translator.translate_batch(strings_list, batch.target_language, batch.source_file)

        if len(results) != len(strings_list):
            print(f"  Warning: Batch result count mismatch")
            results = [{'source': s, 'translation': s} for s in strings_list]

        return results

    def write_translations_back(self, ts_file_path: str, translation_results: List[Dict]):
        with open(ts_file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()

        tree = ET.parse(ts_file_path)
        root = tree.getroot()

        translation_map = {item['source']: item['translation'] for item in translation_results}

        for message in root.iter('message'):
            source_elem = message.find('source')
            translation_elem = message.find('translation')

            if (source_elem is not None and translation_elem is not None and
                translation_elem.get('type') == 'unfinished'):

                source_text = source_elem.text or ''
                if source_text in translation_map:
                    del translation_elem.attrib['type']
                    translation_elem.text = translation_map[source_text]

        import io
        output = io.BytesIO()
        tree.write(output, encoding='utf-8', xml_declaration=True)
        new_content = output.getvalue().decode('utf-8')

        ts_start = original_content.find('<TS')
        new_ts_start = new_content.find('<TS')
        ts_end = original_content.find('</TS>') + 6

        final_content = original_content[:ts_start] + new_content[new_ts_start:]

        with open(ts_file_path, 'w', encoding='utf-8') as f:
            f.write(final_content)

    def process_directory(self, directory_path: str):
        ts_files = list(Path(directory_path).glob('*.ts'))
        print(f"\nFound {len(ts_files)} TS files")

        filtered_files = [
            f for f in ts_files
            if not ('_en.ts' in str(f) or '_en_' in str(f).lower()) or 'zh_CN' in str(f)
        ]
        print(f"Filtered {len(filtered_files)} files to translate\n")

        total_translated = 0
        success_count = 0
        failed_files = []

        start_time = time.time()

        for ts_file in filtered_files:
            try:
                original_count = len(self.find_unfinished_translations(str(ts_file)))
                self.translate_single_file(str(ts_file))
                success_count += 1
                total_translated += original_count
            except Exception as e:
                print(f"  Error processing {ts_file}: {str(e)}")
                failed_files.append(str(ts_file))

        elapsed = time.time() - start_time

        print("\n" + "=" * 50)
        print("Translation Statistics:")
        print(f"  Success: {success_count}/{len(filtered_files)} files")
        print(f"  Total translated: {total_translated} strings")
        print(f"  Time elapsed: {elapsed:.2f} seconds")
        print(f"  Average speed: {total_translated/elapsed:.1f} strings/sec")
        if failed_files:
            print(f"  Failed files: {len(failed_files)}")
            for f in failed_files:
                print(f"    - {f}")
        print("=" * 50)


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Qt Translation Assistant (Parallel)')
    parser.add_argument('path', help='TS file or directory path')
    parser.add_argument('--config', default='qt_translation_config.json',
                        help='Config file path')
    parser.add_argument('--batch-size', type=int, default=20,
                        help='Number of strings per batch (default 20)')
    parser.add_argument('--max-workers', type=int, default=3,
                        help='Number of parallel workers (default 3)')
    parser.add_argument('--create-config', action='store_true',
                        help='Create config file template')

    args = parser.parse_args()

    if args.create_config:
        config = {
            "api_url": "http://localhost:8080/v1/chat/completions",
            "api_key": "your-api-key-here",
            "model": "qwen3-coder-flash",
            "temperature": 0.3
        }
        with open(args.config, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
        print(f"Config created: {args.config}")
        return

    try:
        assistant = QtTranslationAssistant(
            config_path=args.config,
            batch_size=args.batch_size,
            max_workers=args.max_workers
        )

        if os.path.isfile(args.path):
            assistant.translate_single_file(args.path)
        elif os.path.isdir(args.path):
            assistant.process_directory(args.path)
        else:
            print(f"Error: Path not found: {args.path}")

    except FileNotFoundError as e:
        print(f"Error: {str(e)}")
        print("Hint: Use --create-config to create config file")
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
