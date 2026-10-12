# github

Manages webhooks on GitHub repositories through the GitHub REST API, using the `git_webhook` type and its `github` provider.

Forked from [abrader-gms](https://github.com/abrader/abrader-gms). The upstream GitLab and Stash providers, and the deploy key, group and `gms_webhook` types, were removed in 2.0.0.

## Usage

```puppet
git_webhook { 'devops_receive_hook':
  ensure             => present,
  provider           => 'github',
  project_name       => 'mindhivenz/devops-control',
  webhook_url        => 'https://user:pass@puppet.example.com:21947/api/v1/r10k/environment',
  token              => $github_token,
  secret             => $webhook_secret,
  disable_ssl_verify => true,
}
```

The agent finds an existing hook by its URL. With `ensure => present` it adds a JSON `web` hook if no hook in the repository calls `webhook_url`. With `ensure => absent` it deletes that hook. An existing hook's `secret` and `disable_ssl_verify` are not updated.

## Parameters

| Parameter | Description |
|-----------|-------------|
| `name` | A unique title for the webhook. |
| `ensure` | `present` (default) or `absent`. |
| `project_name` | Required. The repository, as `owner/repo`. |
| `webhook_url` | Required. The URL GitHub calls when the repository changes. It may carry basic auth credentials. |
| `token` | A GitHub API token. Give either `token` or `token_file`, not both. |
| `token_file` | The path to a file on the agent that holds the token. |
| `secret` | The secret GitHub uses to sign webhook payloads. |
| `disable_ssl_verify` | When `true`, GitHub skips certificate verification when it calls `webhook_url`. Use it for a self-signed endpoint, such as a puppetserver certificate. Defaults to `false`. |
| `server_url` | The API base URL. Defaults to `https://api.github.com`. Set it to `https://<host>/api/v3` for GitHub Enterprise. |

The token needs the `admin:repo_hook` scope, or for a fine-grained token, read and write access to the repository's webhooks.

The agent verifies GitHub's API certificate. `disable_ssl_verify` only affects GitHub's calls to `webhook_url`.

## Debugging

Run the agent with `--debug` to log each API request's method and URL.

## Development

The module is managed with [jig](https://github.com/voxpupuli/jig). Validation and unit tests run inside the [VoxBox](https://github.com/voxpupuli/container-voxbox) container, so the only host requirements are jig and Docker (or Podman).

### Setup

Install jig from its [releases](https://github.com/voxpupuli/jig/releases), then point its runner at the same VoxBox image CI uses (see `VOXBOX_IMAGE` in `.github/workflows/ci.yml`):

```shell
export JIG_RUNNER_TYPE=voxbox
export JIG_RUNNER_IMAGE=ghcr.io/voxpupuli/voxbox:10.1.0-openvox8.30.0@sha256:01bb8ce5e24d5b111934660f75e2786b4d7c7adcaa7518a564856d1d3041d10d
```

To make this permanent, put the equivalent `[runner]` section in your jig config file instead (see the [jig voxbox docs](https://github.com/voxpupuli/jig/blob/main/docs/voxbox.md)).

### Validate and test

```shell
jig validate     # syntax, puppet-lint and rubocop
jig test unit    # rspec-puppet unit tests
```

Run a single spec file by calling the container directly:

```shell
docker run --rm -v "$PWD:/repo" -e SPEC=spec/unit/puppet/provider/git_webhook/github_spec.rb "$JIG_RUNNER_IMAGE" spec
```

### Build

```shell
jig build
```

The package is written to `pkg/`. Which files are packaged is controlled by the `[build]` section of `jig.toml`.
