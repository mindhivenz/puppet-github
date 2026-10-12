# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:git_webhook) do
  let(:required) do
    {
      name: 'devops_recieve_hook',
      webhook_url: 'https://puppet.example.com:21947/api/v1/r10k/environment',
      token: 'some_token',
      project_name: 'mindhivenz/devops-control',
    }
  end

  def webhook(attributes = {})
    described_class.new(required.merge(attributes).compact)
  end

  it 'is present by default' do
    expect(webhook[:ensure]).to eq(:present)
  end

  it 'can be absent' do
    expect(webhook(ensure: :absent)[:ensure]).to eq(:absent)
  end

  it 'strips whitespace from the token, project_name, webhook_url and secret' do
    resource = webhook(token: " some_token\n", project_name: " a/b\n", webhook_url: " https://x.example.com/hook\n", secret: " some_secret\n")

    expect([resource[:token], resource[:project_name], resource[:webhook_url], resource[:secret]]).to eq(['some_token', 'a/b', 'https://x.example.com/hook', 'some_secret'])
  end

  it 'verifies the webhook certificate by default' do
    expect(webhook[:disable_ssl_verify]).to be(false)
  end

  it 'rejects a non-boolean disable_ssl_verify' do
    expect { webhook(disable_ssl_verify: 'sometimes') }.to raise_error(Puppet::Error, %r{disable_ssl_verify})
  end

  it 'requires a name' do
    expect { described_class.new({}) }.to raise_error(Puppet::Error, %r{Title or name must be provided})
  end

  it 'accepts a token_file instead of a token' do
    expect(webhook(token: nil, token_file: '/etc/github_token')[:token_file]).to eq('/etc/github_token')
  end

  it 'rejects both a token and a token_file' do
    expect { webhook(token_file: '/etc/github_token') }.to raise_error(Puppet::Error, %r{mutually exclusive})
  end

  it 'requires a token or token_file' do
    expect { webhook(token: nil) }.to raise_error(Puppet::Error, %r{token or token_file})
  end

  %i[webhook_url project_name].each do |attribute|
    it "requires #{attribute}" do
      expect { webhook(attribute => nil) }.to raise_error(Puppet::Error, %r{#{attribute} is required})
    end
  end

  it 'rejects a webhook_url containing whitespace' do
    expect { webhook(webhook_url: 'https://x.example.com/a hook') }.to raise_error(Puppet::Error, %r{webhook URL must be fully qualified})
  end

  it 'rejects a webhook_url without a scheme' do
    expect { webhook(webhook_url: 'puppet.example.com/hook') }.to raise_error(Puppet::Error, %r{webhook URL must be fully qualified})
  end

  it 'rejects a non-String webhook_url as not fully qualified' do
    expect { webhook(webhook_url: 42) }.to raise_error(Puppet::Error, %r{webhook URL must be fully qualified})
  end

  ['devops-control', 'a/b/c', 'mindhivenz/devops control'].each do |project_name|
    it "rejects project_name '#{project_name}', which is not owner/repo" do
      expect { webhook(project_name: project_name) }.to raise_error(Puppet::Error, %r{owner/repo})
    end
  end

  it 'accepts an http or https server_url' do
    expect(webhook(server_url: 'http://github.example.com/api/v3')[:server_url]).to eq('http://github.example.com/api/v3')
  end

  it 'drops a trailing slash from server_url' do
    expect(webhook(server_url: 'https://github.example.com/api/v3/')[:server_url]).to eq('https://github.example.com/api/v3')
  end

  it 'rejects a non-String server_url as not fully qualified' do
    expect { webhook(server_url: 42) }.to raise_error(Puppet::Error, %r{server URL must be fully qualified})
  end

  it 'rejects a server_url without a scheme' do
    expect { webhook(server_url: 'github.example.com') }.to raise_error(Puppet::Error, %r{server URL must be fully qualified})
  end
end
