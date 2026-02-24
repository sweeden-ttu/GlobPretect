// blooming_directed_graph_filter_agents – Swift collection.
// Filter nodes by receiver, action_where, action_client, repo name.

import Foundation

public struct Node {
    public var name: String
    public var path: String
    public var owner: String?
    public var repo: String?
    public var slug: String
    public init(name: String, path: String, owner: String?, repo: String?, slug: String) {
        self.name = name
        self.path = path
        self.owner = owner
        self.repo = repo
        self.slug = slug
    }
}

public enum BloomingDirectedGraphFilterAgents {
    public static func filterByReceiver(_ nodes: [Node], receiver: String) -> [Node] {
        guard receiver == "github" || receiver == "hpcc" else { return nodes }
        return nodes.filter { $0.owner != nil && $0.repo != nil }
    }

    public static func filterByActionWhere(_ nodes: [Node], where where_: String) -> [Node] {
        guard where_ == "github" || where_ == "hpcc" else { return nodes }
        return nodes.filter {
            where_ == "github" ? $0.name.contains("github") : $0.name.lowercased().contains("hpcc")
        }
    }

    public static func filterByActionClient(_ nodes: [Node], client: String) -> [Node] {
        guard client == "macbook" || client == "rockydesktop" else { return nodes }
        return nodes.filter {
            client == "macbook" ? $0.name.contains("owner") : $0.name.contains("quay")
        }
    }

    public static func filterByRepoName(_ nodes: [Node], pattern: String) -> [Node] {
        return nodes.filter { $0.name.contains(pattern) }
    }
}
