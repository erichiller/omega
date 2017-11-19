# git



# Configuration

[Git configuration documentation](https://git-scm.com/docs/git-config)

For diagnostics of configuration issues, check what directives are enabled, and their sources with `git config --list --show-origin`

In Omega, the configuration is redirected to `config/` via the environment variable `GIT_CONFIG` which allows for user overrides in `~/.gitconfig`

## Paths

Config files only support the expansion of:
	• ~/
	• ~
	• ./
If those are not the prefix, git will search all subdirectories as if **/ had been prepended

If the pattern ends with / then ** will be automatically appended. For example, foo/ becomes foo/**

Symlinks are NOT followed

../ is NOT resolved

## Git Color / `git status`

[git-status](https://git-scm.com/docs/git-status)

## `~/.gitconfig` colors

```
color.branch
color.branch.current
color.branch.local
color.branch.plain
color.branch.remote
color.decorate.branch
color.decorate.HEAD
color.decorate.remoteBranch
color.decorate.stash
color.decorate.tag
color.diff
color.diff.commit
color.diff.frag
color.diff.func
color.diff.meta
color.diff.new
color.diff.old
color.diff.plain
color.diff.whitespace
color.grep
color.grep.context
color.grep.filename
color.grep.function
color.grep.linenumber
color.grep.match
color.grep.selected
color.grep.separator
color.interactive
color.interactive.error
color.interactive.header
color.interactive.help
color.interactive.prompt
color.pager
color.showbranch
color.status
color.status.added
color.status.changed
color.status.header
color.status.nobranch
color.status.untracked
color.status.updated
color.ui
```


## Color Values:
* normal
* black
* red
* green
* yellow
* blue
* magenta
* cyan
* white

# Attribute values
* bold - _windows (conemu) at least does not support true **Bold**, so this is shown as a **Brightening** of colors_
* dim - color is darkened
* ul (underline) - _the `ul` decoration does not cause any graphical change_
* blink - _blink I image is not windows-possible, this resulted in a gray background and sharp white lettering_
* reverse - swap foreground and background

See more on [colors available](https://git-scm.com/docs/git-config/#git-config-color)




### See:

https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration

http://cheat.errtheblog.com/s/git



# GitHub


## Docs / README

GitHub will automatically use any top level `README.md` or documentation under `docs/` as the front page for a repo. see: <https://help.github.com/articles/about-readmes/>