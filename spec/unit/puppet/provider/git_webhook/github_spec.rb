# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:git_webhook).provider(:github) do
  def hooks_uri
    'https://api.github.com/repos/mindhivenz/devops-control/hooks'
  end

  def webhook_url
    'https://puppet:puppet@puppet.example.com:21947/api/v1/r10k/environment'
  end

  def github_headers
    {
      'Accept' => 'application/vnd.github.v3+json',
      'Authorization' => 'token some_token',
      'Content-Type' => 'application/json',
      'User-Agent' => 'puppet-github',
    }
  end

  let(:attributes) { {} }
  let(:resource) do
    Puppet::Type.type(:git_webhook).new(
      {
        name: 'devops_recieve_hook',
        webhook_url: webhook_url,
        token: 'some_token',
        project_name: 'mindhivenz/devops-control',
        provider: :github,
      }.merge(attributes).compact,
    )
  end
  let(:provider) { resource.provider }

  def json_response(body, status: 200)
    { status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
  end

  def stub_hooks(*urls)
    hooks = urls.each_with_index.map { |url, index| { id: index + 7, config: { url: url } } }
    stub_request(:get, hooks_uri).with(headers: github_headers, query: { per_page: '100' }).to_return(json_response(hooks))
  end

  it 'is the only git_webhook provider' do
    expect(Puppet::Type.type(:git_webhook).providers).to eq([:github])
  end

  describe '#exists?' do
    it 'is true when a repository hook calls the webhook URL' do
      stub_hooks('https://elsewhere.example.com/hook', webhook_url)

      expect(provider.exists?).to be(true)
    end

    it 'is false when no repository hook calls the webhook URL' do
      stub_hooks('https://elsewhere.example.com/hook')

      expect(provider.exists?).to be(false)
    end

    it 'asks for up to 100 hooks, past the default page size of 30' do
      lookup = stub_hooks

      provider.exists?

      expect(lookup).to have_been_requested
    end

    it 'verifies the certificate of an https server_url' do
      stub_hooks
      allow(Net::HTTP).to receive(:start).and_call_original

      provider.exists?

      expect(Net::HTTP).to have_received(:start).with('api.github.com', 443, use_ssl: true)
    end

    it 'fails with the API message when GitHub rejects the request' do
      stub_request(:get, hooks_uri).with(query: hash_including({})).to_return(json_response({ message: 'Bad credentials' }, status: 401))

      expect { provider.exists? }.to raise_error(Puppet::Error, %r{401.*Bad credentials})
    end

    it 'fails with the raw body when a GitHub error body is not a JSON object' do
      stub_request(:get, hooks_uri).with(query: hash_including({})).to_return(json_response('oops', status: 500))

      expect { provider.exists? }.to raise_error(Puppet::Error, %r{500 "oops"})
    end

    context 'with a GitHub Enterprise server_url' do
      let(:attributes) { { server_url: 'https://github.example.com/api/v3/' } }

      it 'asks that server' do
        lookup = stub_request(:get, 'https://github.example.com/api/v3/repos/mindhivenz/devops-control/hooks').with(query: hash_including({})).to_return(json_response([]))

        provider.exists?

        expect(lookup).to have_been_requested
      end
    end

    context 'with an http server_url' do
      let(:attributes) { { server_url: 'http://github.example.com/api/v3' } }

      it 'connects without TLS' do
        stub_request(:get, %r{\Ahttp://github\.example\.com/}).to_return(json_response([]))
        allow(Net::HTTP).to receive(:start).and_call_original

        provider.exists?

        expect(Net::HTTP).to have_received(:start).with('github.example.com', 80, use_ssl: false)
      end
    end

    context 'with a token_file' do
      let(:token_file) { Tempfile.new('token').tap { |file| file.write("some_token\n") }.tap(&:close) }
      let(:attributes) { { token: nil, token_file: token_file.path } }

      it 'authenticates with the token read from the file' do
        lookup = stub_hooks

        provider.exists?

        expect(lookup).to have_been_requested
      end
    end

    context 'with a missing token_file' do
      let(:attributes) { { token: nil, token_file: '/nonexistent/github_token' } }

      it 'fails naming the token_file' do
        expect { provider.exists? }.to raise_error(Puppet::Error, %r{token_file.*/nonexistent/github_token})
      end
    end
  end

  describe '#create' do
    def stub_create(config)
      stub_request(:post, hooks_uri)
        .with(headers: github_headers, body: { name: 'web', active: true, config: config }.to_json)
        .to_return(json_response({ id: 7 }, status: 201))
    end

    it 'adds a JSON web hook calling the webhook URL' do
      create = stub_create(url: webhook_url, content_type: 'json')

      provider.create

      expect(create).to have_been_requested
    end

    context 'with disable_ssl_verify and a secret' do
      let(:attributes) { { disable_ssl_verify: true, secret: 'some_secret' } }

      it 'asks GitHub to skip certificate checks and sign payloads' do
        create = stub_create(url: webhook_url, content_type: 'json', insecure_ssl: 1, secret: 'some_secret')

        provider.create

        expect(create).to have_been_requested
      end
    end

    it 'fails with the API message when GitHub rejects the hook' do
      stub_request(:post, hooks_uri).to_return(json_response({ message: 'Validation Failed' }, status: 422))

      expect { provider.create }.to raise_error(Puppet::Error, %r{422.*Validation Failed})
    end
  end

  describe '#destroy' do
    it 'looks up the hooks once when Puppet checks existence before destroying' do
      lookup = stub_hooks(webhook_url)
      stub_request(:delete, "#{hooks_uri}/7").to_return(status: 204)

      provider.exists?
      provider.destroy

      expect(lookup).to have_been_requested.once
    end

    it 'deletes the hook calling the webhook URL' do
      stub_hooks('https://elsewhere.example.com/hook', webhook_url)
      delete = stub_request(:delete, "#{hooks_uri}/8").with(headers: github_headers).to_return(status: 204)

      provider.destroy

      expect(delete).to have_been_requested
    end

    it 'deletes nothing when no hook calls the webhook URL' do
      stub_hooks('https://elsewhere.example.com/hook')

      provider.destroy

      expect(a_request(:delete, %r{.*})).not_to have_been_made
    end

    it 'fails with the API message when GitHub refuses the deletion' do
      stub_hooks(webhook_url)
      stub_request(:delete, "#{hooks_uri}/7").to_return(json_response({ message: 'Not Found' }, status: 404))

      expect { provider.destroy }.to raise_error(Puppet::Error, %r{404.*Not Found})
    end

    context 'with whitespace around project_name' do
      let(:attributes) { { project_name: " mindhivenz/devops-control\n" } }

      it 'deletes the hook in the project named without the whitespace' do
        stub_hooks(webhook_url)
        delete = stub_request(:delete, "#{hooks_uri}/7").to_return(status: 204)

        provider.destroy

        expect(delete).to have_been_requested
      end
    end
  end
end
