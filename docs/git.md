# git


# GitHub

## Configuration

[Git Config documentation](https://git-scm.com/docs/git-config)

For diagnostics of configuration issues, check what directives are enabled, and their sources with `git config --list --show-origin`

In Omega, the configuraiton is redirected to `config/` via the environment variable `GIT_CONFIG` which allows for user overrides in `~/.gitconfig`

## Docs / README

GitHub will automatically use any toplevel `README.md` or documentent under `docs/` as the frontpage for a repo. see: <https://help.github.com/articles/about-readmes/>

