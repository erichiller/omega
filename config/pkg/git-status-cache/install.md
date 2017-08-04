




posh-git is required from
   http://dahlbyk.github.io/posh-git/
   https://github.com/dahlbyk/posh-git/blob/master/README.md
retrieve the `/src` directory from it and scrap the rest


# Status Format
By default, the status summary has the following format:

```
[{HEAD-name} +A ~B -C !D | +E ~F -G !H]
{HEAD-name} is the current branch, or the SHA of a detached HEAD
Cyan means the branch matches its remote
Green means the branch is ahead of its remote (green light to push)
Red means the branch is behind its remote
Yellow means the branch is both ahead of and behind its remote
ABCD represent the index; EFGH represent the working directory
+ = Added files
~ = Modified files
- = Removed files
! = Conflicted files
As in git status, index status is dark green and working directory status is dark red
For example, a status of [master +0 ~2 -1 | +1 ~1 -0] corresponds to the following git status:

# On branch master
#
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#        modified:   this-changed.txt
#        modified:   this-too.txt
#        deleted:    gone.ps1
#
# Changed but not updated:
#   (use "git add <file>..." to update what will be committed)
#   (use "git checkout -- <file>..." to discard changes in working directory)
#
#        modified:   not-staged.ps1
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#
#        new.file
```






git clone https://github.com/cmarcusreid/git-status-cache-posh-client

run `install.ps1` to get `bin/GitStatusCache.exe` ; this will update as well.

test for commands:
- Get-GitStatusCacheStatistics
- Get-GitStatusFromCache

