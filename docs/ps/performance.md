# PowerShell Performance

**TOO MANY PATHS ON `$PSModulesPath` will cause _extreme_ slowness**

Example:
Adding just `%LOCALAPPDATA%` to `$PSModulesPath` made this module's load times go from ~1s to **~14s**