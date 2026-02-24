package agents;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * blooming_directed_graph_filter_agents – Java collection.
 * Filter nodes by receiver, action_where, action_client, repo name.
 */
public final class Collection {

    public static List<Node> filterByReceiver(List<Node> nodes, String receiver) {
        if (!"github".equals(receiver) && !"hpcc".equals(receiver)) return nodes;
        List<Node> out = new ArrayList<>();
        for (Node n : nodes) {
            if (n.owner != null && n.repo != null) out.add(n);
        }
        return out;
    }

    public static List<Node> filterByActionWhere(List<Node> nodes, String where) {
        if (!"github".equals(where) && !"hpcc".equals(where)) return nodes;
        List<Node> out = new ArrayList<>();
        for (Node n : nodes) {
            if ("github".equals(where) && n.name.contains("github")) out.add(n);
            else if ("hpcc".equals(where) && n.name.toLowerCase().contains("hpcc")) out.add(n);
        }
        return out;
    }

    public static List<Node> filterByActionClient(List<Node> nodes, String client) {
        if (!"macbook".equals(client) && !"rockydesktop".equals(client)) return nodes;
        List<Node> out = new ArrayList<>();
        for (Node n : nodes) {
            if ("macbook".equals(client) && n.name.contains("owner")) out.add(n);
            else if ("rockydesktop".equals(client) && n.name.contains("quay")) out.add(n);
        }
        return out;
    }

    public static List<Node> filterByRepoName(List<Node> nodes, Pattern pattern) {
        List<Node> out = new ArrayList<>();
        for (Node n : nodes) {
            if (pattern.matcher(n.name).find()) out.add(n);
        }
        return out;
    }

    public static class Node {
        public String name, path, owner, repo, slug;
    }
}
