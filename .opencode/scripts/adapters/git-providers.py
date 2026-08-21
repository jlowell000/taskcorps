#!/usr/bin/env python3
"""
git-providers.py — abstraction layer for multi-provider Git PR operations.

Supports GitHub (gh CLI), GitLab (glab CLI), and Gitea (gitea CLI).
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import read_file, write_file


class GitProvider:
    """Base class for Git provider abstractions."""

    name: str = "base"

    def create_pr(self, title: str, body: str, head: str, base: str, labels: list[str] | None = None) -> str | None:
        raise NotImplementedError

    def pr_url(self) -> str | None:
        raise NotImplementedError


class GitHubProvider(GitProvider):
    name = "github"

    def __init__(self, repo: str):
        self.repo = repo

    def create_pr(self, title: str, body: str, head: str, base: str, labels: list[str] | None = None) -> str | None:
        cmd = [
            "gh", "pr", "create",
            "--repo", self.repo,
            "--title", title,
            "--body", body,
            "--head", head,
            "--base", base,
        ]
        if labels:
            for label in labels:
                cmd.extend(["--label", label])
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"ERROR: gh pr create failed: {e.stderr}", file=sys.stderr)
            return None

    def pr_url(self) -> str | None:
        return None  # URL is returned directly by create_pr


class GitLabProvider(GitProvider):
    name = "gitlab"

    def __init__(self, project: str):
        self.project = project

    def create_pr(self, title: str, body: str, head: str, base: str, labels: list[str] | None = None) -> str | None:
        cmd = [
            "glab", "mr", "create",
            "--source", head,
            "--target", base,
            "--title", title,
            "--description", body,
        ]
        if labels:
            for label in labels:
                cmd.extend(["--label", label])
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"ERROR: glab mr create failed: {e.stderr}", file=sys.stderr)
            return None

    def pr_url(self) -> str | None:
        return None


class GiteaProvider(GitProvider):
    name = "gitea"

    def __init__(self, repo: str):
        self.repo = repo

    def create_pr(self, title: str, body: str, head: str, base: str, labels: list[str] | None = None) -> str | None:
        # Gitea CLI is less standardized; use API if available
        # Fallback: print instructions for manual creation
        print(f"TODO: Gitea PR creation requires API integration. Create PR manually for {head} -> {base}")
        return None

    def pr_url(self) -> str | None:
        return None


def detect_provider(pr_capabilities: Path) -> GitProvider | None:
    """Detect the Git provider from pr-capabilities.md."""
    text = read_file(pr_capabilities)
    for line in text.splitlines():
        if line.startswith("- Provider:"):
            provider = line.split(":", 1)[1].strip().lower()
            if provider == "github":
                return GitHubProvider("")
            elif provider == "gitlab":
                return GitLabProvider("")
            elif provider == "gitea":
                return GiteaProvider("")
    return None


def create_pr(provider: GitProvider, title: str, body: str, head: str, base: str, labels: list[str] | None = None) -> str | None:
    """Create a PR/MR using the detected provider."""
    return provider.create_pr(title, body, head, base, labels)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: adapters/git-providers.py <pr-capabilities.md>", file=sys.stderr)
        sys.exit(1)
    provider = detect_provider(Path(sys.argv[1]))
    if provider:
        print(f"Detected provider: {provider.name}")
    else:
        print("No provider detected")
