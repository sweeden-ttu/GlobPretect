using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace BloomingDirectedGraphFilterAgents;

/// <summary>blooming_directed_graph_filter_agents – C# collection.</summary>
public static class Collection
{
    public static List<Node> FilterByReceiver(List<Node> nodes, string receiver)
    {
        if (receiver != "github" && receiver != "hpcc") return nodes;
        return nodes.Where(n => n.Owner != null && n.Repo != null).ToList();
    }

    public static List<Node> FilterByActionWhere(List<Node> nodes, string where)
    {
        if (where != "github" && where != "hpcc") return nodes;
        return nodes.Where(n =>
            (where == "github" && (n.Name?.Contains("github") == true)) ||
            (where == "hpcc" && (n.Name?.ToLowerInvariant().Contains("hpcc") == true))).ToList();
    }

    public static List<Node> FilterByActionClient(List<Node> nodes, string client)
    {
        if (client != "macbook" && client != "rockydesktop") return nodes;
        return nodes.Where(n =>
            (client == "macbook" && (n.Name?.Contains("owner") == true)) ||
            (client == "rockydesktop" && (n.Name?.Contains("quay") == true))).ToList();
    }

    public static List<Node> FilterByRepoName(List<Node> nodes, Regex pattern)
    {
        return nodes.Where(n => n.Name != null && pattern.IsMatch(n.Name)).ToList();
    }

    public class Node
    {
        public string? Name { get; set; }
        public string? Path { get; set; }
        public string? Owner { get; set; }
        public string? Repo { get; set; }
        public string? Slug { get; set; }
    }
}
