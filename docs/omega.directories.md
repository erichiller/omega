# Git submodules for user configurations

`/etc/local`


```powershell
# first ensure that the repository you intend to use for local configurations is created on github
# set the repository name to $OMEGA_CONF.localConfigRepo
# set your git username = $OMEGA_CONF.gituser
git submodule add "https://github.com/${$OMEGA_CONF.gituser}/${$OMEGA_CONF.localConfigRepo}" $( Join-Path $OMEGA_CONF.basedir "etc/local" )


# to initialise a repo which contains submodules, there are two ways:
# (1) , after cloning the main repo:
git submodule init
git submodule update
# (2) , at the initial clone of the Main (parent repo) do it all:
git clone --recursize https://github.com/MAIN/MAINREPO


# post submodule changes (send new changes to remote)
git push --recurse-submodules=check

# update submodules (receive new changes from remote)
# (from any directory) with:
git submodule update --remote
# otherwise a normal `git pull` will work if you are _in the submodule's directory_
```

## Note to Development:

* Ensure that `.gitmodules` is **IGNORED** ;; but in `.gitignore`

## Reference

[git-book: submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

# Directory Structure

      Directory     | Role
--------------------|--------------------------------------------------------------------------------
/bin                | programs that all users access; ie: wget, curl (but that the SYSTEM doesn't require)
/etc                | configuraiton files
  /etc/local        | user localized config files, these will be within a submodule
/lib                | for system program, omega functions.ps1, core operations
/opt                | for optionally installed system programs, ie. Nodejs, vim, etc...
/sbin               | system REQUIRED programs, that which omega depends on; ie. PSColor, oh-my-posh

Designed around [standard linux directories](http://www.pathname.com/fhs/pub/fhs-2.3.html)


