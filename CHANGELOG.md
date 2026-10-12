## 2026-10-12 - Release 2.0.0
### Summary

Breaking: only the `git_webhook` type and its `github` provider remain. Moved from PDK to jig, with VoxBox CI.

#### Removed
- Types `git_deploy_key`, `git_groupteam`, `git_groupteam_member` and `gms_webhook`
- The `gitlab` and `stash` providers for `git_webhook`
- `git_webhook` parameters that only those providers used: `username`, `password`, `project_id`, `repo_name`, `hook_exe`, `hook_exe_params`, `merge_request_events`, `tag_push_events` and `issue_events`
- The `puppetlabs/stdlib` dependency, which no code used
- Support for Puppet older than 7 and for operating systems other than Ubuntu 20.04, 22.04 and 24.04

#### Fixes
- The provider verifies the GitHub API certificate. It previously skipped verification on every request that carried the token
- A GitHub error response now fails with the status and GitHub's message, instead of a TypeError
- `project_name`, `webhook_url` and `token` are stripped of surrounding whitespace everywhere they are used
- A resource missing `webhook_url`, `project_name` or a token now fails validation, instead of crashing the provider
- `webhook_url` must be an http or https URL and `project_name` must be `owner/repo`, so a bad value fails validation instead of at GitHub
- A trailing `/` on `server_url` is dropped, instead of building `//repos/...`
- A repository with more than 30 hooks no longer reports the webhook absent and then fails to create it
- An unreadable `token_file` fails with a Puppet error naming it, instead of a raw Errno
- `disable_ssl_verify` really defaults to `false`. Its previous default was ignored, though unset behaved the same
- `ensure => absent` looks up the repository hooks once instead of twice, and `token_file` is read once per run
- The API User-Agent is `puppet-github`, not `puppet-gms`

- - -

## 2016-06-07 - Release 1.0.3
### Summary

This release is an attempt to fix the permissions issue users discovered in the previous Forge package mentioned in this issue: [Wrong rights on lib/puppet/provider/gms_webhook/github.rb](https://github.com/abrader/abrader-gms/issues/28)

## 2016-02-10 - Release 1.0.2
### Summary

This release is mainly a wrap of fixes and updates prior to a major rewrite

#### Fixes
- Deploy Keys
  - All Providers
    - Removed restriction on SSL port
  - Stash
    - Fixed issue with initial deploy key not getting created

- - -

## 2015-10-20 - Release 1.0.1
### Summary

This release is purely to expose debugging functionality previously assumed as released. ;)

- - -

## 2015-08-24 - Release 1.0.0
### Summary

This release introduces Stash support for both deploy keys and webhooks.

The [README](https://github.com/abrader/abrader-gms/blob/master/README.md) has been updated to include the usage notes for these parameters.

#### Features
- New parameters - `Stash`
  - `username`
  - `password`
  - `repo_name`

- - -

## 2015-06-12 - Release 0.0.9
### Summary

v0.0.8 Tarball on Puppet Forge had bad permissions for the Webhook provider. Thanks to @bhechinger for the heads up.

- - -

## 2015-04-20 - Release 0.0.8
### Summary

This release is because I simply missed the updated CHANGELOG when packaging the previous module release.

- - -

## 2015-04-20 - Release 0.0.7

### Summary

This release is for the purpose of easing the regex on the git_webhook type so Basic HTTP Auth included with an URL is an accepted parameter.

- - -

## 2015-02-24 - Release 0.0.6
### Summary

This release has many new parameters enabling the ability to set different triggers for webhooks on GitLab and disabling ssl checks on GitHub.  Minor cleanup as well.

The [README](https://github.com/abrader/abrader-gms/blob/master/README.md) has been updated to include the usage notes for these parameters.

#### Features
- New parameters - `GitLab`
  - `merge_request_events`
  - `tag_push_events`
  - `issue_events`
- New parameters - `GitHub`
  - `disable_ssl_verify`

- - -
