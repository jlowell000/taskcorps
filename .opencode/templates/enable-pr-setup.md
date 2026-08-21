# Enabling PR Creation for Taskcorps

Taskcorps uses the `gh` CLI to open pull requests against your remote. If PR creation
is disabled for this project, follow these steps to enable it.

## Prerequisites

1. **Install the GitHub CLI.** `gh` must be on your `PATH`.
   ```sh
   # macOS
   brew install gh

   # Debian/Ubuntu
   sudo apt install gh

   # Or download from https://cli.github.com
   ```

2. **Authenticate.** Run `gh auth login` and follow the prompts.
   - Choose GitHub.com (or your GitHub Enterprise host).
   - Choose HTTPS (recommended) or SSH.
   - Grant the `repo` scope (required to create PRs).
   - Verify with `gh auth status` — it should show a logged-in account for the correct host.

3. **Verify the remote.** Ensure the project has a remote named `origin` that points to a
   GitHub repository:
   ```sh
   git remote get-url origin
   ```
   Output should look like `git@github.com:owner/repo.git` or `https://github.com/owner/repo.git`.

## Enabling

Once `gh auth status` confirms you are authenticated:

1. Open `.team/context/pr-capabilities.md`.
2. Set `Enabled: yes`.
3. Set `Auth:` to the account shown by `gh auth status`.
4. Run `/release` to verify PR creation works.

## Troubleshooting

- **"gh: command not found"** — install the CLI (see above) and restart your shell.
- **"not authenticated"** — run `gh auth login` and complete the OAuth flow.
- **"resource not accessible by integration"** — your PAT is missing the `repo` scope.
  Re-run `gh auth login` and ensure you grant `repo` (not just `public_repo`).
- **SSH remote but HTTPS auth** — `gh` handles both. If you see host mismatches, run
  `gh auth login` again and pick the same protocol as your remote URL.
- **GitHub Enterprise** — during `gh auth login`, choose "GitHub Enterprise" and enter
  your GHE hostname. Then verify with `gh auth status --hostname <your-ghe-host>`.
