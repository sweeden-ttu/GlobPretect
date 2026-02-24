# frozen_string_literal: true

# blooming_directed_graph_filter_agents – Ruby collection.
# Filter nodes/edges by receiver, action_where, action_client, repo name.
# Use with BloomingDirectedGraph (see src/ruby/blooming_directed_graph.rb).

module BloomingDirectedGraphFilterAgents
  # Nodes are hashes: { name:, path:, owner:, repo:, slug: }
  # Edges are hashes: { from:, to: }

  def self.filter_by_receiver(nodes, receiver)
    return nodes unless %w[github hpcc].include?(receiver.to_s)
    nodes.select do |n|
      next false unless n[:owner] && n[:repo]
      receiver == "github" ? n[:repo] : true
    end
  end

  def self.filter_by_action_where(nodes, where)
    return nodes unless %w[github hpcc].include?(where.to_s)
    nodes.select do |n|
      key = n[:name]
      case where
      when "github" then key.to_s.include?("github")
      when "hpcc" then key.to_s.include?("hpcc")
      else false
      end
    end
  end

  def self.filter_by_action_client(nodes, client)
    return nodes unless %w[macbook rockydesktop].include?(client.to_s)
    nodes.select do |n|
      name = n[:name].to_s
      (client == "macbook" && (name.start_with?("owner_") || name.include?("owner"))) ||
        (client == "rockydesktop" && (name.start_with?("quay_") || name.include?("quay")))
    end
  end

  def self.filter_by_repo_name(nodes, pattern)
    re = pattern.is_a?(Regexp) ? pattern : Regexp.new(Regexp.escape(pattern.to_s))
    nodes.select { |n| n[:name].to_s =~ re }
  end
end
