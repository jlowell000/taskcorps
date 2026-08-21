# Enabling PR Creation for Taskcorps

Taskcorps supports multiple Git providers for PR creation. Choose your provider below and follow the setup steps.

## Supported Providers

| Provider | CLI | Config field |
| --- | --- | --- |
| GitHub | `gh` | `gh auth login` |
| GitLab | `glab` | `glab auth login` |
| Gitea | `gitea` or API | Manual token config |

## Prerequisites

1. **Install your provider's CLI.** It must be on your `PATH`.
   - **GitHub (`gh`):**
     ```sh
     # macOS
     brew install gh
     # Debian/Ubuntu
     sudo apt install gh
     # Or download from https://cli.github.com
     ```
   - **GitLab (`glab`):**
     ```sh
     # macOS
     brew install glab
     # Debian/Ubuntu
     sudo apt install glab
     # Or download from https://github.com/profclems/glab
     ```
   - **Gitea:** Use the `gitea` CLI or configure an API token in `.team/context/pr-capabilities.md`.

2. **Authenticate.**
   - **GitHub:** Run `gh auth login` and follow the prompts. Grant the `repo` scope.
     Verify with `gh auth status`.
   - **GitLab:** Run `glab auth login` and follow the prompts.
     Verify with `glab auth status`.
   - **Gitea:** Generate a personal access token in your Gitea instance settings
     (requires `read:repository`, `write:repository` scopes).

3. **Verify the remote.** Ensure the project has a remote named `origin`:
   ```sh
   git remote get-url origin
   ```
   - GitHub: `git@github.com:owner/repo.git` or `https://github.com/owner/repo.git`
   - GitLab: `git@gitlab.com:owner/repo.git` or `https://gitlab.com/owner/repo.git`
   - Gitea: `git@gitea.example.com:owner/repo.git` or `https://gitea.example.com/owner/repo.git`

## Enabling

1. Open `.team/context/pr-capabilities.md`.
2. Set `Enabled: yes`.
3. Set `Provider:` to your provider (`github`, `gitlab`, or `gitea`).
4. Set `Method:` to the CLI you installed (`gh CLI`, `glab CLI`, or `gitea CLI`).
5. Set `Auth:` to the account shown by your CLI's auth status.
6. Run `/release` to verify PR creation works.

## Troubleshooting

- **"gh: command not found"** — install the GitHub CLI and restart your shell.
- **"glab: command not found"** — install the GitLab CLI and restart your shell.
- **"not authenticated"** — run the appropriate `auth login` command for your provider.
- **"resource not accessible by integration"** — your PAT is missing the required scopes.
  Re-run auth login and ensure you grant `repo` (GitHub) or equivalent (GitLab/Gitea).
- **SSH remote but HTTPS auth** — most CLIs handle both. If you see host mismatches,
  re-run auth login and pick the same protocol as your remote URL.
- **GitHub Enterprise** — during `gh auth login`, choose "GitHub Enterprise" and enter
  your GHE hostname. Then verify with `gh auth status --hostname <your-ghe-host>`.
- **GitLab self-managed** — during `glab auth login`, choose "Self-hosted GitLab" and
  enter your instance URL.
- **Gitea** — ensure your API token has `read:repository` and `write:repository` scopes.
  If the CLI is unavailable, PR creation will prompt for manual creation.
