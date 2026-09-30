---
name: conventional-commits
description: >-
  Rules and procedures for writing conventional git commit messages with strictly formatted targets and single colon delimiters.
---

# Conventional Commits

## Overview
This skill defines commit message standards for the repository. All commits must strictly follow the Conventional Commits format to ensure consistent and parseable version control history.

## Formatting Rules
Commit messages must follow the format `<type>: <description>` or `<type>(<scope>): <description>`. The colon `:` character directly following the target type is the only permitted punctuation symbol in the summary line. Emojis, exclamation marks, trailing periods, and non-alphanumeric decorators are strictly prohibited in commit titles. Commit summary lines must remain under 72 characters and use imperative verbs such as add, fix, update, remove, or refactor.

## Allowed Commit Types
The `feat` type indicates a new feature or functionality. The `fix` type indicates a bug fix. The `docs` type indicates documentation updates. The `style` type indicates formatting adjustments without logic changes. The `refactor` type indicates code refactoring without feature addition or bug fixes. The `perf` type indicates performance enhancements. The `test` type indicates addition or correction of automated test suites. The `chore` type indicates maintenance, tooling, or build configuration adjustments.
