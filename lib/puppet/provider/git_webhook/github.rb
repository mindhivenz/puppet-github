# frozen_string_literal: true

require 'json'
require 'net/http'

Puppet::Type.type(:git_webhook).provide(:github) do
  desc 'Manages repository webhooks through the GitHub REST API.'

  def exists?
    !hook_id.nil?
  end

  def create
    github_request(Net::HTTP::Post, hooks_path, { name: 'web', active: true, config: hook_config })
  end

  def destroy
    id = hook_id
    github_request(Net::HTTP::Delete, "#{hooks_path}/#{id}") if id
  end

  private

  def hooks_path
    "/repos/#{resource[:project_name]}/hooks"
  end

  def hooks
    @hooks ||= github_request(Net::HTTP::Get, "#{hooks_path}?per_page=100")
  end

  def hook_id
    hooks.find { |hook| hook.dig('config', 'url') == resource[:webhook_url] }&.fetch('id')
  end

  def hook_config
    {
      url: resource[:webhook_url],
      content_type: 'json',
      insecure_ssl: (1 if resource[:disable_ssl_verify]),
      secret: resource[:secret],
    }.compact
  end

  def token
    @token ||= resource[:token] || token_from_file
  end

  def token_from_file
    File.read(resource[:token_file]).strip
  rescue SystemCallError => e
    raise Puppet::Error, "Cannot read token_file: #{e.message}"
  end

  def github_request(method, path, body = nil)
    uri = URI("#{resource[:server_url]}#{path}")
    request = method.new(uri)
    request['Accept'] = 'application/vnd.github.v3+json'
    request['Authorization'] = "token #{token}"
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'puppet-github'
    request.body = body.to_json if body
    Puppet.debug("git_webhook github: #{request.method} #{uri}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    raise Puppet::Error, "GitHub #{request.method} #{uri} failed: #{response.code} #{error_message(response)}" unless response.is_a?(Net::HTTPSuccess)

    response.body.to_s.empty? ? nil : JSON.parse(response.body)
  end

  def error_message(response)
    parsed = JSON.parse(response.body)
    parsed.is_a?(Hash) ? parsed.fetch('message', response.body) : response.body
  rescue JSON::ParserError, TypeError
    response.body
  end
end
