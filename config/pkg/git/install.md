


# data
repo is       : https://github.com/git-for-windows/git/releases
link format is: https://github.com/git-for-windows/git/releases/download/v2.13.3.windows.1/Git-2.13.3-64-bit.tar.bz2

# config editing
The global gitconfig can be relocated in several ways.

1) move the entire `$HOME` directory by putting `@set HOME=\blah\blah` in the git.bat ala
   https://stackoverflow.com/questions/28690019/how-to-change-gitconfig-location
2) by adding a `@set GIT_CONFIG=%BaseDir%\config\omega.gitconfig` variable to the `git.bat`
