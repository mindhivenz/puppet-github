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

See [AGENTS.md](AGENTS.md) for checking changes, the VoxBox gotchas and building. It is shared by every module and synced from [mindhivenz/msync](https://github.com/mindhivenz/msync).
