# frozen_string_literal: true

# blooming_directed_graph_trigger_process_agent – Ruby.
# IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
# Triggers processes across languages, projects, repositories, clusters, models.
# Action types: workflow_dispatch, job_submit, git_push, git_fetch, fetch_merge, push_merge, pull_merge, run_script, notify.

require "json"
require "net/http"
require "uri"

module BloomingDirectedGraphTriggerProcessAgent
  GITHUB_API = "https://api.github.com"

  def self.trigger(node:, action:, payload: {})
    case action.to_s
    when "workflow_dispatch"
      trigger_workflow_dispatch(node, payload)
    when "git_push"
      trigger_git(node, "push", payload)
    when "git_fetch"
      trigger_git(node, "fetch", payload)
    when "fetch_merge"
      trigger_fetch_merge(node, payload)
    when "push_merge"
      trigger_push_merge(node, payload)
    when "pull_merge"
      trigger_git(node, "pull", payload)
    when "job_submit"
      trigger_hpcc_job(node, payload)
    when "run_script"
      trigger_run_script(node, payload)
    when "notify"
      trigger_notify(node, payload)
    else
      { ok: false, error: "unknown action: #{action}" }
    end
  end

  def self.trigger_workflow_dispatch(node, payload)
    owner = node[:owner] || payload[:owner]
    repo = node[:repo] || payload[:repo] || node[:slug]
    workflow_id = payload[:workflow_id] || payload["workflow_id"]
    ref = payload[:ref] || payload["ref"] || "main"
    return { ok: false, error: "missing owner/repo/workflow_id" } unless owner && repo && workflow_id
    token = ENV["GITHUB_TOKEN"]
    return { ok: false, error: "GITHUB_TOKEN not set" } unless token
    uri = URI("#{GITHUB_API}/repos/#{owner}/#{repo}/actions/workflows/#{workflow_id}/dispatches")
    req = Net::HTTP::Post.new(uri)
    req["Accept"] = "application/vnd.github.v3+json"
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"
    req.body = { ref: ref }.merge(payload[:inputs] ? { inputs: payload[:inputs] } : {}).to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    res.is_a?(Net::HTTPSuccess) ? { ok: true } : { ok: false, error: "HTTP #{res.code}" }
  end

  def self.trigger_git(node, cmd, payload)
    path = node[:path] || payload[:path]
    return { ok: false, error: "missing path" } unless path && File.directory?(path)
    system("git", "-C", path, cmd.to_s, *Array(payload[:args]))
    { ok: $?.success? }
  end

  def self.trigger_fetch_merge(node, payload)
    path = node[:path] || payload[:path]
    return { ok: false, error: "missing path" } unless path && File.directory?(path)
    remote = payload[:remote] || "origin"
    branch = payload[:branch] || "main"
    system("git", "-C", path, "fetch", remote) && system("git", "-C", path, "merge", "#{remote}/#{branch}")
    { ok: $?.success? }
  end

  def self.trigger_push_merge(node, payload)
    path = node[:path] || payload[:path]
    return { ok: false, error: "missing path" } unless path && File.directory?(path)
    remote = payload[:remote] || "origin"
    branch = payload[:branch] || "main"
    system("git", "-C", path, "merge", branch) # optional
    system("git", "-C", path, "push", remote, *Array(payload[:args]))
    { ok: $?.success? }
  end

  def self.trigger_hpcc_job(node, payload)
    path = node[:path] || payload[:path]
    script = payload[:script] || "job.sh"
    return { ok: false, error: "missing path/script" } unless path
    system("sbatch", File.join(path, script))
    { ok: $?.success? }
  end

  def self.trigger_run_script(node, payload)
    path = node[:path] || payload[:path]
    script = payload[:script]
    return { ok: false, error: "missing path/script" } unless path && script
    system(script, chdir: path)
    { ok: $?.success? }
  end

  def self.trigger_notify(node, payload)
    { ok: true, message: "notify not implemented (platform-specific)" }
  end
end
