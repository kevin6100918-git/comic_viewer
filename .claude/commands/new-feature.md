You are helping the user create a new feature branch for the comic_viewer Flutter project.

The user wants to start working on a new feature. Follow these steps exactly:

1. Read the argument provided by the user (the feature name). If no argument was provided, ask the user to provide a short feature name (kebab-case, e.g. `reader-zoom`, `bookshelf-sort`).

2. Sanitize the feature name: convert spaces to hyphens, lowercase everything, strip special characters. The final branch name must be `feature/<sanitized-name>`.

3. Run these git commands in sequence using PowerShell:
   a. `git status` — confirm the working tree is clean. If there are uncommitted changes, warn the user and ask whether to stash them or abort.
   b. `git checkout master` — switch to master first.
   c. `git pull origin master` — pull latest (skip if no remote is configured and say so).
   d. `git checkout -b feature/<sanitized-name>` — create and switch to the new branch.

4. After the branch is created, confirm success and tell the user:
   - The exact branch name that was created.
   - That they are now on the new branch and can start coding.

Do NOT commit anything. Do NOT create any files. Only create the branch and check it out.

$ARGUMENTS
