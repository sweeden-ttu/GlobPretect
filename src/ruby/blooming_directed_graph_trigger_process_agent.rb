# frozen_string_literal: true

# Blooming-directed-graph trigger process agent.
# Triggers the appropriate process across languages, projects, repositories, clusters, and models.
# Uses context_key (one of 20) or (language, project, repository, cluster, model) to decide action.

require "json"
require "shellwords"

TRIGGER_AGENT_JSON = File.expand_path("../blooming_directed_graph_filter_agents.json", __FILE__)

module BloomingDirectedGraphTriggerProcessAgent
  def self.spec
    @spec ||= begin
      data = JSON.parse(File.read(TRIGGER_AGENT_JSON))
      data["blooming_directed_graph_trigger_process_agent"] || {}
    end
  end

  # Resolve context_key from (language, project, repository, cluster, model) if needed.
  def self.resolve_context_key(context_key: nil, language: nil, project: nil, repository: nil, cluster: nil, model: nil)
    return context_key if context_key && !context_key.empty?
    return nil unless cluster && model
    env = case cluster.to_s.downcase
          when "github" then (project.to_s.include?("owner") ? "owner_github" : (project.to_s.include?("hpcc") ? "hpcc_github" : "quay_github"))
          when "hpcc"   then (project.to_s.include?("owner") ? "owner_hpcc" : "quay_hpcc")
          else "owner_github"
          end
    mod = { "granite" => "granite", "deepseek" => "deepseek", "qwen" => "qwen", "codellama" => "codellama" }[model.to_s.downcase] || "granite"
    "#{env}_#{mod}"
  end

  # Return action type for context_key: :github, :hpcc, or :local
  def self.action_for_key(context_key)
    return :local unless context_key
    return :github if context_key.to_s.include?("github")
    return :hpcc   if context_key.to_s.include?("hpcc")
    :local
  end

  # Trigger the process. Returns a hash with :action, :command or :error.
  def self.trigger(context_key: nil, language: nil, project: nil, repository: nil, cluster: nil, model: nil, projects_dir: nil)
    key = resolve_context_key(context_key: context_key, language: language, project: project, repository: repository, cluster: cluster, model: model)
    action = action_for_key(key)
    projects_dir = projects_dir || ENV["PROJECTS_DIR"] || File.expand_path("~/projects")
    scripts_dir = File.join(File.dirname(File.dirname(__FILE__)), "..", "scripts")
    case action
    when :github
      sync_script = File.join(scripts_dir, "daily-github-sync.sh")
      cmd = "CONTEXT_KEY=#{Shellwords.shellescape(key)} PROJECTS_DIR=#{Shellwords.shellescape(projects_dir)} #{Shellwords.shellescape(sync_script)} sync"
      { action: :github, context_key: key, command: cmd }
    when :hpcc
      connect_script = File.join(scripts_dir, "connect-hpcc.sh")
      cmd = "CONTEXT_KEY=#{Shellwords.shellescape(key)} #{Shellwords.shellescape(connect_script)}"
      { action: :hpcc, context_key: key, command: cmd }
    when :local
      { action: :local, context_key: key, command: nil }
    else
      { error: "Could not resolve context_key or action" }
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  key = ARGV[0] || ENV["CONTEXT_KEY"]
  result = BloomingDirectedGraphTriggerProcessAgent.trigger(context_key: key)
  puts result.to_json
end
