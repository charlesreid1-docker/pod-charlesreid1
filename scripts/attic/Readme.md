# the scripts attic

These four scripts use a git clone or
git pull command that is useful because
it uses a non-standard dot git/clone 
directory layout.

However, these do nothing to ensure
that said folders exist and have 
correct permissions, and in some
cases these scripts were fed incorrect
info, so better to use the python
templates in the parent directory.

```
git_clone_data.sh
git_clone_www.sh
git_pull_data.sh
git_pull_www.sh
```

