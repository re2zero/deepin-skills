# Deepin Skills Collection

## Overview

This directory contains a collection of skills for deepin project development, covering Git workflow, Qt/C++ development, translation management, release automation, and GitHub code review reporting.

## Skills Directory

### Qt/C++ Unit Testing Skills

#### [qt-unittest-build](qt-unittest-build/) ⭐ **推荐**

**Purpose**: 为 Qt 项目自动生成单元测试框架，采用"固定脚本 + 动态AI"架构。

**When to use**: 用户请求为 Qt 项目设置单元测试框架，或需要自动化生成 CMake 配置和测试文件时。

**Key features**:
- **全自动流程**: 1句话即可完成，无需手动步骤
- **扁平化架构**: Skill 路由 + 子 Agent 全栈执行，无中间层
- **内置模板**: CMakeLists.txt、测试文件、stub-ext 工具、运行脚本全部内置
- **智能分析**: 自动识别项目结构、Qt 版本、第三方依赖
- **多框架支持**: Qt Test、Google Test、Catch2 任选

**Resources**:
- `SKILL.md` - 技能文档（任务路由器）
- `.opencode/agent/qt-unit-test-executor.md` - 子 Agent（全栈执行者）
- `README.md` - 详细使用文档

**Usage**:
```bash
# 在 OpenCode 中直接输入
请为当前项目生成单元测试框架

# 或显式调用
使用 qt-unittest-build 技能
```

**执行流程**:
1. Skill 触发 → 子 Agent 自动调用
2. 项目分析 → CMakeLists.txt、依赖、Qt 版本
3. 文件生成 → tests/ 目录、CMake 配置、测试文件
4. 用户确认 → write 工具询问确认
5. 完成 → 提供构建和运行命令

#### [qt-unittest-make](qt-unittest-make/) ⭐ **推荐**

**Purpose**: 为 Qt 项目生成单元测试代码，使用 LSP 分析类结构，自动生成 100% 函数覆盖率的测试用例。支持模块批量生成和单个类增量补全。

**When to use**: 用户请求为指定模块或类创建单元测试，补全测试用例，或创建测试文件。

**Key features**:
- **100% 函数覆盖率**: 自动为每个 public/protected 函数生成测试用例
- **智能 LSP 分析**: 使用 `lsp_document_symbols`, `lsp_goto_definition`, `lsp_find_references` 精确分析类结构
- **Stub 智能生成**: 内化完整的 Stub 模式库，自动生成 UI、信号、虚函数、重载函数的 Stub
- **智能 CMake 合并**: 根据项目具体情况优化合并，确保通用性
- **支持增量更新**: 对比现有测试，补全未覆盖的函数
- **强制验证构建**: 生成后必须编译成功才能报告完成
- **严谨错误处理**: 每个编译错误最多重试 3 次，最大循环 10 次

**Resources**:
- `SKILL.md` - 技能文档（任务路由器）
- `agent/unittest-generator.md` - 子 Agent（测试代码生成器）
- `resources/templates/` - 测试代码模板（google_test_base.cpp, stub_patterns.cpp, cmake_module.txt）
- `README.md` - 详细使用文档

**Usage**:
```bash
# 为模块批量生成测试
为 src/lib/ui 模块创建单元测试

# 为单个类创建/补全测试
为 MyClass 创建单元测试
为 MyClass 补全测试
```

**执行流程**:
1. Skill 触发 → 子 Agent 自动调用
2. 分析项目结构（LSP）→ 生成测试文件（100% 覆盖率）
3. 智能合并 CMake 配置 → 验证构建（必须成功）

**关键特性**:
- ✅ 不依赖外部文档（所有知识已内化）
- ✅ 重试逻辑清晰（每个错误重试 3 次，最大循环 10 次）
- ✅ 错误分类完善（5 类错误处理）
- ✅ 验证约束强制（编译必须成功才能报告完成）

### Qt Translation Assistant Skills

#### [qt-translation-assistant](qt-translation-assistant/) ⭐ **推荐**

**Purpose**: Automated translation tool for Qt projects using AI models to translate TS (Translation Source) files with parallel processing and 100% format preservation.

**When to use**: User requests translating Qt project localization files (TS files), automating translation workflows, or setting up multilingual support for Qt applications.

**Key features**:
- **Smart parsing**: Detects all unfinished translation formats (single-line, multi-line, self-closing)
- **100% format preservation**: Line-number based replacement preserves all original formatting
- **Parallel processing**: ThreadPoolExecutor with configurable batch size and workers
- **Error isolation**: Single batch failure doesn't affect others
- **Retry logic**: Automatic retries with exponential backoff
- **Support multiple AI providers**: OpenAI, Anthropic, DeepSeek, local servers

**Architecture**:
- **TranslationWorker**: Handles AI API calls with retry logic
- **QtTranslationAssistant**: Main orchestration with parallel batch processing
- **Line-number based replacement**: Ensures 100% format preservation

**Resources**:
- `SKILL.md` - Skill documentation
- `translate.py` - Main script with parallel processing
- `README.md` - Detailed usage documentation
- `test_format_preservation.py` - Format preservation test script

**Usage**:
```bash
# Translate entire directory of TS files
python translate.py /path/to/ts/files/ --batch-size 30 --max-workers 3

# Translate specific file
python translate.py /path/to/specific/file.ts

# Create configuration file
python translate.py --create-config
```

### Git Workflow Skills

#### [git-commit-workflow](git-commit-workflow/) ⭐ **推荐**

**Purpose**: 智能化的 Git 提交流程工具，支持中文团队规范，包含 PMS 单号和 GitHub Issue 追踪功能。

**When to use**: 用户请求提交代码、查看 git 状态、暂存文件，或需要生成符合团队规范的提交信息时。

**Key features**:
- **零脚本依赖**: 仅使用 git 命令，完全通用，无编译和脚本依赖
- **智能解析**: AI 自动识别并解析 PMS URL 和 GitHub Issue URL
- **结构化提交**: 生成符合规范的中英文双语提交信息
- **强制确认**: 用户完全掌控提交内容，绝不出错
- **格式约束**: Body 行不超过 80 字符，中英文成对出现
- **完全通用**: 任何支持 Bash 工具的 AI Agent 都可使用

**提交信息格式**:
```
<type>[optional scope]: <English description>

[English body - optional, max 80 chars per line]

[Chinese body - optional, max 80 chars per line, must pair with English]

Log: <简洁的中文描述>
PMS: <BUG-number or TASK-number>
Issue: Fixes #<number> or owner/repo#<number>
Influence: <用中文说明影响范围>
```

**智能解析能力**:
- PMS 单号：从 URL 或直接输入中自动提取（BUG-XXXXX/TASK-XXXXX）
- GitHub Issue：从 URL 或简写格式智能解析完整 Issue 标识
- 仓库上下文：通过 `git remote get-url origin` 推断仓库名

**Resources**:
- `SKILL.md` - 技能文档（工作流程指南）
- `README.md` - 详细使用文档
- `templates/commit-examples.md` - 提交格式示例和类型参考

**Usage**:
```bash
# 在 OpenCode 中直接输入
帮我提交代码
commit changes

# 或显式调用
使用 git-commit-workflow 技能
```

**执行流程**:
1. 检查状态 → git status
2. 选择文件 → 交互式暂存
3. 查看差异 → git diff --staged
4. 生成草稿 → AI 智能解析 PMS/Issue
5. 用户确认 → 用户修改或确认
6. 执行提交 → git commit -m "<message>"

**关键特性**:
- ✅ 零依赖（仅 git 命令）
- ✅ AI 智能解析（无需脚本处理 URL）
- ✅ 强制确认（绝不自动提交）
- ✅ 格式约束（80 字符限制、中英文双语）

### Qt Compatibility Build Skills

#### [qt-compatibility-build](qt-compatibility-build/) ⭐ **推荐**

**Purpose**: 为 Qt/CMake 项目实现 deepin V25/V20 双版本支持，消除硬编码的 Qt5/Qt6 和 DTK5/DTK6 版本引用，实现自动检测和动态库链接。

**When to use**: CMakeLists.txt 中存在硬编码的 `Qt5::`/`Qt6::` 或 `Dtk::`/`Dtk6::`，需要统一配置支持 V25 (Qt6) 和 V20 (Qt5) 版本时。

**Key features**:
- **自动 Qt 检测**: `find_package(QT NAMES Qt6 Qt5 ...)` 自动检测
- **动态 DTK 映射**: Qt6 → DTK6，Qt5 → DTK5 基于检测自动映射
- **库链接变量化**: `Qt${QT_VERSION_MAJOR}::` 和 `Dtk${DTK_VERSION_MAJOR}::` 消除硬编码
- **独立 Control 文件**: debian/control (V25) 和 debian/control.1 (V20) 分离管理
- **紧凑文档**: 864 词快速参考，仅保留核心模式和必要示例

**文件规范**:
| 文件 | Deepin 版本 | Qt 版本 |
|------|------------|---------|
| `debian/control` | V25 | Qt6 |
| `debian/control.1` | V20 | Qt5 |

**Resources**:
- `SKILL.md` - 技能文档（紧凑参考，仅核心模式）

**Usage**:
```bash
# 添加 Qt5/Qt6 兼容支持
add Qt5/Qt6 dual version support
update CMakeLists.txt for Qt5/Qt6
fix hard-coded Qt versions in CMake
```

**执行流程**:
1. 添加 Qt 检测：`find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)`
2. 添加 DTK 映射：`if (QT_VERSION_MAJOR MATCHES 6) set(DTK_VERSION_MAJOR 6)`
3. 替换所有 find_package：`Qt${QT_VERSION_MAJOR}` / `Dtk${DTK_VERSION_MAJOR}`
4. 替换所有 target_link_libraries：`Qt${QT_VERSION_MAJOR}::` / `Dtk${DTK_VERSION_MAJOR}::`
5. 创建 debian/control (V25) 和 debian/control.1 (V20)
6. 验证 V25 编译和 V20 编译

**关键特性**:
- ✅ 消除硬编码版本引用
- ✅ 单一 CMake 配置适应 Qt5/Qt6
- ✅ 快速参考表格（替换模式）
- ✅ 精准 Common Mistakes 表格
- ✅ Red Flags 速查清单

### Release Management Skills

#### [create-release-tags](create-release-tags/)

**Purpose**: Automates Debian package version releases by updating debian/changelog and linglong.yaml (if present), generating change summaries from git log, and creating version commits.

**When to use**: Releasing new versions for Debian-based projects, preparing test releases, bumping version numbers with changelog updates, or projects with/without linglong.yaml.

**Key features**:
- **Version management**: Supports explicit version specification or auto-increment (patch only)
- **Changelog automation**: Generates change summaries from git log between version tags
- **Multi-format support**: Handles both debian/changelog and linglong.yaml (including arch-specific variants)
- **Standard commit format**: Creates commits following deepin project conventions
- **Linglong version handling**: Updates only first three version parts (X.Y.Z.1 pattern)
- **Author integration**: Uses git config user.name/user.email for changelog entries

**Resources**:
- `SKILL.md` - Skill documentation

**Usage**:
```bash
# Release specific version
tag release 6.5.47

# Auto-increment patch version
tag release

# Prepare test version
tag prepare-test 6.5.47

# Alternative trigger phrases
release new version
bump version
update version
prepare for release
```

**Execution Flow**:
1. Detect project type (debian/changelog, linglong.yaml presence)
2. Determine target version (specified or auto-increment patch)
3. Generate change summary from git log since last tag
4. Get author info from git config
5. Update debian/changelog with proper formatting
6. Update all linglong.yaml files (X.Y.Z.N → X.Y.Z.N)
7. Create commit with standard message format

### GitHub Review Skills

#### [github-review-report](github-review-report/) ⭐ **推荐**

**Purpose**: 从 GitHub 仓库生成中文格式代码走查报告，支持按时间范围、分支、reviewer筛选，自动分类问题为15种类型并标记严重程度，生成Excel报表。

**When to use**: 用户请求生成项目的代码走查报告（中文格式）、跟踪特定时间段的review活动、分析特定reviewer的反馈时。

**Key features**:
- **标准化数据源**: 始终使用 GitHub API (`gh` CLI) 而非本地 git log
- **精确时间解析**: 支持相对时间表达（"这个月"、"上周"、"半个月"）
- **灵活过滤**: fnmatch 模式匹配 include/exclude reviewers
- **智能分类**: 自动将review建议分类为15种问题类型（书写规范、安全漏洞等）
- **严重程度标记**: 根据问题类型自动标记严重程度（安全漏洞、内存泄漏=严重；其他=一般）
- **中文摘要**: 将review建议摘要为中文（≤50字符）
- **固定Reviewer**: Reviewer列固定填入值（默认 liuzheng）
- **Excel格式**: pandas + openpyxl 生成标准格式报表
- **紧急模式**: 5分钟内限制10个PR快速交付

**输出文件名格式**: `模块名-代码走查报告-yyyymmdd.xlsx`

**Excel报表列**（严格13列，中文格式，无额外列）:
| 列名 | 数据源 | 说明 |
|--------|--------|------|
| 序号 | 自增序号 | 自动递增（1,2,3...） |
| 包名 | --module-name 参数 | 项目名/模块名 |
| 仓库地址 | `https://github.com/{repo}` | GitHub仓库URL |
| 代码提交地址 | `pr['url']` | PR链接 |
| 问题来源 | 映射表（1-3） | commit log(1) / 代码(2) / 注释(3) |
| 问题描述 | 摘要后的review建议 | 中文摘要（≤50字符） |
| 严重程度 | 根据问题类型确定 | 严重（类型8,12）；一般（其他） |
| 影响分析 | 同问题描述 | 中文摘要（≤50字符） |
| 问题类型 | 分类表（1-15） | 书写规范、安全漏洞、内存泄漏等15类 |
| 提出人 | --reviewer 参数 | 固定值（默认 liuzheng） |
| 提出时间 | `review['submittedAt']` | Review提交时间 |
| 解决人 | `pr['mergedBy']['login']` | 合并者 |
| 计划解决时间 | `pr['mergedAt']` | 合并时间 |
| 实际解决时间 | `pr['mergedAt']` | 合并时间（同计划解决时间） |
| 提出人确认是否验收通过 | 固定值 | 填"是" |
| 问题状态 | 根据合并状态 | 已合并="关闭"；未合并="解决中" |

**Resources**:
- `SKILL.md` - 技能文档（决策流程图、分类表、关键词表）
- `generator.py` - 可执行Python脚本（完整实现）

**Usage**:
```bash
# 基本使用 - 这个月的review报告
python generator.py \
  --repo linuxdeepin/dde-cooperation \
  --since "this month" \
  --module-name dde-cooperation

# 指定reviewer和分支 - 半个月的master分支review
python generator.py \
  --repo linuxdeepin/dde-cooperation \
  --since "last 15 days" \
  --module-name dde-cooperation \
  --reviewer liuzheng \
  --base master \
  --include "sourcery-*" \
  --exclude "*-bot"

# 紧急模式 - 上周的review，5分钟内交付
python generator.py \
  --repo linuxdeepin/dde-cooperation \
  --since "last week" \
  --module-name dde-cooperation \
  --limit 10
```

**执行流程**:
1. 解析时间范围（"这个月" → 2026-01-01 to 2026-01-22）
2. 通过 `gh pr list` API 获取PR数据
3. 应用reviewer过滤（include/exclude fnmatch模式）
4. 通过 `gh pr view` 获取详细PR数据（comments, reviews）
5. 提取review建议并分类问题类型（15种）和问题来源（3种）
6. 根据问题类型确定严重程度（严重/一般）
7. 摘要为中文（≤50字符）
8. 生成Excel（严格13列，中文格式）
9. 输出文件：`模块名-代码走查报告-yyyymmdd.xlsx`

**问题类型分类（15种）**:
| 序号 | 分类 | 说明 |
|------|------|------|
| 1 | 书写规范 | 命名、格式等 |
| 2 | 日志规范 | 日志输出规范 |
| 3 | 头文件规范 | .h文件规范 |
| 4 | 变量规范 | 变量命名规则 |
| 5 | 常量规范 | 常量定义规则 |
| 6 | 宏定义规范 | 宏定义规则 |
| 7 | 指针规范 | 指针使用规范 |
| 8 | 代码安全漏洞 | 安全漏洞、缓冲区溢出等 |
| 9 | 代码冗余 | 重复代码、冗余逻辑 |
| 10 | 注释规范 | 注释格式规范 |
| 11 | 编译警告 | 编译警告相关 |
| 12 | 内存未释放 | 内存泄漏、未释放 |
| 13 | 提交内容规范 | commit信息规范 |
| 14 | 不符合需求 | 需求不符 |
| 15 | 其他 | 其他问题 |

**严重程度分类**:
- **严重**: 问题类型8（代码安全漏洞）、12（内存未释放）
- **一般**: 其他所有类型（1-7, 9-11, 13-15）

**关键特性**:
- ✅ 决策流程图（帮助快速判断）
- ✅ 15种问题类型分类
- ✅ 3种问题来源分类
- ✅ 严重程度自动标记
- ✅ 中文格式输出（列名、问题类型、严重程度等）
- ✅ 固定Reviewer值（填入liuzheng）
- ✅ 问题状态自动判断（关闭/解决中）
- ✅ 边缘情况处理（空结果、紧急模式）

## Dependencies

### Git Workflow Skill

**System requirements**:
- git (any version with standard CLI commands)

**AI Agent requirements**:
- Bash tool support
- Natural language understanding for URL parsing

### Framework Skill

**Script dependencies**:
- bash
- cmake
- Google Test (libgtest-dev, libgmock-dev)
- lcov, genhtml (for coverage reports)

**Stub-ext source**: Local `resources/testutils/` directory (bundled)

### Generation Skill

**LSP tools** (required):
- lsp_document_symbols
- lsp_goto_definition
- lsp_find_references

**Testing libraries**:
- Google Test (gtest/gmock)
- stub-ext (from framework skill)

### Release Management Skill

**System requirements**:
- git
- bash
- date (RFC 2822 format support: `date -R`)
- sed, find (standard Unix utilities)

**Git configuration** (required):
- git config user.name
- git config user.email

### GitHub Review Report Skill

**System requirements**:
- Python 3.8+
- gh CLI (GitHub CLI tool)
- git config for repository access

**Python dependencies**:
- pandas
- openpyxl

**Git configuration** (required):
- GitHub authentication (gh auth login)
- Repository access permissions

### Qt Compatibility Build Skill

**System requirements**:
- cmake (3.1.0+)
- gcc/g++ or other C++ compiler
- V25 dependencies (for Qt6 builds): qt6-base-dev, libdtk6widget-dev, etc.
- V20 dependencies (for Qt5 builds): qtbase5-dev, libdtkwidget-dev, etc.

**AI Agent requirements**:
- Bash tool support
- File read/write tools for CMakeLists.txt and debian/control
- Edit/Write tools for code compatibility code (if needed)

## Testing Workflow

1. **Generate framework** (qt-unittest-build):
    ```
    请为当前项目生成单元测试框架
    ```

2. **Generate tests for classes** (qt-unittest-make):
    - User: "为 src/lib/ui 模块创建单元测试"
    - AI: Uses LSP tools → Analyzes class → Generates tests (100% coverage) → Validates build

3. **Run tests**:
    ```bash
    cd build-autotests
    ctest --output-on-failure
    ```

## Git Workflow

1. **Check git status**:
    ```
    查看git状态
    ```

2. **Commit changes**:
    ```
    帮我提交代码
    ```
    - User: Selects files to stage
    - AI: Analyzes changes → Generates structured commit message → Parses PMS/Issue
    - User: Confirms or edits the commit message
    - AI: Executes `git commit`

## File Structure

```
deepin-skills/
├── README.md                                  # This file
├── github-review-report/                        # GitHub review report skill
│   ├── SKILL.md                               # Skill documentation (1559 words)
│   └── generator.py                            # Executable Python script
├── qt-compatibility-build/                    # Qt5/Qt6 auto-detection compatibility skill
│   └── SKILL.md                               # Skill documentation
├── git-commit-workflow/                       # Git workflow skill
│   ├── SKILL.md                               # Skill documentation
│   ├── README.md                              # Detailed usage documentation
│   └── templates/commit-examples.md           # Commit format examples
├── qt-unittest-build/                         # Framework generation skill
│   ├── SKILL.md                               # Skill documentation
│   ├── .opencode/agent/qt-unit-test-executor.md  # Subagent
│   └── README.md                              # Detailed usage documentation
├── qt-unittest-make/                          # Test generation skill
│   ├── SKILL.md                               # Skill documentation
│   ├── agent/unittest-generator.md            # Subagent
│   └── README.md                              # Detailed usage documentation
├── qt-translation-assistant/                  # Translation assistant skill
│   ├── SKILL.md                               # Skill documentation
│   ├── translate.py                           # Main script with parallel processing
│   ├── README.md                              # Detailed usage documentation
│   └── test_format_preservation.py            # Format preservation test
└── create-release-tags/                       # Release management skill
    └── SKILL.md                               # Skill documentation
```

## Adding New Skills

To add a new skill to this collection:

1. **Create skill directory**: `deepin-skills/skill-name/`
2. **Write SKILL.md**: Follow writing-skills guidelines
   - YAML frontmatter (name + description)
   - Description starts with "Use when..."
   - <500 words for frequently-loaded skills
   - Clear Iron Laws and Red Flags
3. **Add resources**: Any bundled resources in `resources/` subdirectory
4. **Update README**: Add skill entry to this document with:
   - Purpose
   - When to use
   - Key features
   - Resources
   - Usage example

## Design Principles

All skills in this collection follow writing-skills TDD methodology:

1. **RED Phase**: Identify pressure scenarios and baseline rationalizations
2. **GREEN Phase**: Write minimal skills addressing specific failures
3. **REFACTOR Phase**: Compress to <500 words, close all loopholes

Each skill includes:
- Clear Iron Laws (no exceptions)
- Red Flags (stop indicators)
- Rationalization tables (counters to common excuses)
- Quick Reference (efficient lookup)
- Common Mistakes (what goes wrong and fixes)

## Token Efficiency

- qt-unittest-build: <500 words
- qt-unittest-make: <500 words
- qt-translation-assistant: <500 words
- qt-compatibility-build: 864 words (technique skill with CMake patterns and dependency mapping)
- create-release-tags: <1000 words (technique skill with implementation details)
- github-review-report: 1559 words (technique skill with decision flow and pattern matching tables)

Most skills under 500-word limit for efficient context usage. Technique skills with implementation details may exceed this limit but should remain concise.

## Compatibility

**Tested with**:
- Qt5/Qt6 projects
- CMake 3.10+
- Google Test 1.8+
- C++14/17/20
- GitHub repositories (via `gh` CLI)
- Python 3.8+ (pandas, openpyxl)

**Supports**:
- Libraries (libs/)
- Plugins (plugins/)
- Services (services/)
- Standalone source files
- GitHub-hosted repositories

## License

Part of dde-file-manager project (GPL-3.0-or-later).
