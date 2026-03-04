# SUMA config

## env

File `/etc/salt/master.d/environment.conf`:

```
saltenv: prod
```

## gitFS

File `/etc/salt/master.d/gitfs.conf`:

```
# salt
#
fileserver_backend:
  - roots
  - gitfs

gitfs_remotes:
  - https://github.com/ElShaKo/SUSE.git:
    - base: salt
    - root: salt/states

gitfs_provider: pygit2
gitfs_update_interval: 60


# pillar
#
ext_pillar:
  - git:
    - salt https://github.com/ElShaKo/SUSE.git:
      - root: salt/pillar

git_pillar_provider: pygit2
git_pillar_insecure_auth: True
git_pillar_includes: True

pillar_source_merging_strategy: smart
pillar_merge_lists: True
```

