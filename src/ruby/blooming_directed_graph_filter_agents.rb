# frozen_string_literal: true

# Blooming-directed-graph filter agents collection.
# Ten agents: ruby, typescript, python, csharp, java, bash, zsh, git, github, hpcc.
# Each agent filters nodes/edges by its criteria (language, shell, vcs, or action_where).

require "json"

FILTER_AGENTS_JSON = File.expand_path("../blooming_directed_graph_filter_agents.json", __FILE__)

module BloomingDirectedGraphFilterAgents
  def self.load_collection
    data = JSON.parse(File.read(FILTER_AGENTS_JSON))
    data["blooming_directed_graph_filter_agents"] || []
  end

  def self.collection
    @collection ||= load_collection
  end

  def self.by_id(agent_id)
    collection.find { |a| a["id"] == agent_id.to_s }
  end

  def self.filter_nodes_for_agent(nodes, agent_id, context_key: nil)
    agent = by_id(agent_id)
    return nodes unless agent
    criteria = agent["filter_criteria"] || {}
    action_where = criteria["action_where"]
    language = criteria["language"]
    shell = criteria["shell"]
    vcs = criteria["vcs"]
    if action_where
      return nodes if context_key.nil?
      key_where = context_key.include?("github") ? "github" : (context_key.include?("hpcc") ? "hpcc" : nil)
      return key_where == action_where ? nodes : []
    end
    nodes if language || shell || vcs
  end

  def self.agent_ids
    collection.map { |a| a["id"] }
  end
end

if __FILE__ == $PROGRAM_NAME
  puts "Filter agents: #{BloomingDirectedGraphFilterAgents.agent_ids.join(', ')}"
  BloomingDirectedGraphFilterAgents.collection.each do |a|
    puts "  #{a['id']}: #{a['name']} (#{a['role']})"
  end
end
