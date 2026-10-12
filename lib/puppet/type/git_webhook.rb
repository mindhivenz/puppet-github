# frozen_string_literal: true

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:git_webhook) do
  @doc = 'Manages a webhook on a GitHub repository.'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'A unique title for the webhook.'
  end

  newparam(:webhook_url) do
    desc 'The URL GitHub calls when the repository changes. It may carry basic auth credentials.'
    munge { |value| String(value).strip }
    validate do |value|
      raise Puppet::Error, "Git webhook URL must be fully qualified, not '#{value}'" unless String(value).strip.match?(%r{\Ahttps?://\S+\z})
    end
  end

  newparam(:project_name) do
    desc "The repository, as 'owner/repo'."
    munge { |value| String(value).strip }
    validate do |value|
      raise Puppet::Error, "Git project name must be owner/repo, not '#{value}'" unless String(value).strip.match?(%r{\A[^/\s]+/[^/\s]+\z})
    end
  end

  newparam(:token) do
    desc 'The GitHub API token. Mutually exclusive with token_file.'
    munge { |value| String(value).strip }
  end

  newparam(:token_file) do
    desc 'The path to a file on the agent holding the GitHub API token. Mutually exclusive with token.'
    munge { |value| String(value) }
  end

  newparam(:secret) do
    desc 'The secret GitHub uses to sign webhook payloads.'
    munge { |value| String(value).strip }
  end

  newparam(:disable_ssl_verify, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Whether GitHub skips certificate verification when calling webhook_url, for a self-signed endpoint.'
    defaultto :false
  end

  newparam(:server_url) do
    desc 'The GitHub API base URL. Set it for GitHub Enterprise.'
    defaultto 'https://api.github.com'
    munge { |value| String(value).strip.sub(%r{/+\z}, '') }
    validate do |value|
      raise Puppet::Error, "Git server URL must be fully qualified, not '#{value}'" unless String(value).match?(%r{\Ahttps?://})
    end
  end

  validate do
    %i[webhook_url project_name].each do |attribute|
      raise Puppet::Error, "#{attribute} is required" if self[attribute].nil?
    end
    raise Puppet::Error, 'token and token_file are mutually exclusive' if self[:token] && self[:token_file]
    raise Puppet::Error, 'One of token or token_file is required' unless self[:token] || self[:token_file]
  end
end
