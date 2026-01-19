# AGENTS

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
1. Find available skills: `find_skills` tool
2. Load skill: `use_skill` tool with skill_name (e.g., "superpowers:writing-skills")
3. The skill content will load with detailed instructions on how to complete the task
4. Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Always use `find_skills` tool first to discover available skills
- Always use `use_skill` tool with the full skill name (including prefix like "superpowers:")
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless

Skill priority (from highest to lowest):
1. superpowers:writing-skills - TDD-based skill creation methodology (use this first)
2. skill-creator - Fallback for skill creation if superpowers:writing-skills unavailable
</usage>

<available_skills>

<skill>
<name>superpowers:writing-skills</name>
<description>TDD-based skill creation methodology. Use when creating new skills, editing existing skills, or verifying skills work before deployment. Follows RED-GREEN-REFACTOR cycle with pressure scenarios and agent testing.</description>
<location>superpowers</location>
<priority>1</priority>
</skill>

<skill>
<name>skill-creator</name>
<description>Guide for creating effective skills (fallback). This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. Use only if superpowers:writing-skills is unavailable.</description>
<location>project</location>
<priority>2</priority>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
