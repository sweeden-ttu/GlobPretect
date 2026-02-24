package agents;

import java.io.*;
import java.net.http.*;
import java.nio.file.*;
import java.util.*;

/**
 * blooming_directed_graph_trigger_process_agent – Java.
 * IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
 * Triggers processes across languages, projects, repositories, clusters, models.
 */
public final class TriggerProcessAgent {

    public static Map<String, Object> trigger(Collection.Node node, String action, Map<String, Object> payload) {
        if (payload == null) payload = new HashMap<>();
        switch (action) {
            case "workflow_dispatch": return triggerWorkflowDispatch(node, payload);
            case "git_push": return triggerGit(node, "push", payload);
            case "git_fetch": return triggerGit(node, "fetch", payload);
            case "fetch_merge": return triggerFetchMerge(node, payload);
            case "push_merge": return triggerPushMerge(node, payload);
            case "pull_merge": return triggerGit(node, "pull", payload);
            case "job_submit": return triggerHpccJob(node, payload);
            case "run_script": return triggerRunScript(node, payload);
            case "notify": return Map.of("ok", true, "message", "notify not implemented");
            default: return Map.of("ok", false, "error", "unknown action: " + action);
        }
    }

    private static Map<String, Object> triggerWorkflowDispatch(Collection.Node node, Map<String, Object> payload) {
        String owner = (String) payload.getOrDefault("owner", node.owner);
        String repo = (String) payload.getOrDefault("repo", node.repo != null ? node.repo : node.slug);
        String workflowId = (String) payload.get("workflow_id");
        String ref = (String) payload.getOrDefault("ref", "main");
        if (owner == null || repo == null || workflowId == null)
            return Map.of("ok", false, "error", "missing owner/repo/workflow_id");
        String token = System.getenv("GITHUB_TOKEN");
        if (token == null) return Map.of("ok", false, "error", "GITHUB_TOKEN not set");
        try {
            HttpClient client = HttpClient.newHttpClient();
            String body = "{\"ref\":\"" + ref + "\"}";
            HttpRequest req = HttpRequest.newBuilder()
                .uri(java.net.URI.create("https://api.github.com/repos/" + owner + "/" + repo + "/actions/workflows/" + workflowId + "/dispatches"))
                .header("Accept", "application/vnd.github.v3+json")
                .header("Authorization", "Bearer " + token)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();
            HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
            return Map.of("ok", res.statusCode() >= 200 && res.statusCode() < 300);
        } catch (Exception e) {
            return Map.of("ok", false, "error", e.getMessage());
        }
    }

    private static Map<String, Object> triggerGit(Collection.Node node, String cmd, Map<String, Object> payload) {
        String p = node.path != null ? node.path : (String) payload.get("path");
        if (p == null || !Files.isDirectory(Path.of(p))) return Map.of("ok", false, "error", "missing path");
        try {
            ProcessBuilder pb = new ProcessBuilder("git", "-C", p, cmd);
            Process proc = pb.inheritIO().start();
            return Map.of("ok", proc.waitFor() == 0);
        } catch (Exception e) {
            return Map.of("ok", false, "error", e.getMessage());
        }
    }

    private static Map<String, Object> triggerFetchMerge(Collection.Node node, Map<String, Object> payload) {
        String p = node.path != null ? node.path : (String) payload.get("path");
        if (p == null || !Files.isDirectory(Path.of(p))) return Map.of("ok", false, "error", "missing path");
        String remote = (String) payload.getOrDefault("remote", "origin");
        String branch = (String) payload.getOrDefault("branch", "main");
        try {
            Process p1 = new ProcessBuilder("git", "-C", p, "fetch", remote).inheritIO().start();
            if (p1.waitFor() != 0) return Map.of("ok", false);
            Process p2 = new ProcessBuilder("git", "-C", p, "merge", remote + "/" + branch).inheritIO().start();
            return Map.of("ok", p2.waitFor() == 0);
        } catch (Exception e) {
            return Map.of("ok", false, "error", e.getMessage());
        }
    }

    private static Map<String, Object> triggerPushMerge(Collection.Node node, Map<String, Object> payload) {
        String p = node.path != null ? node.path : (String) payload.get("path");
        if (p == null || !Files.isDirectory(Path.of(p))) return Map.of("ok", false, "error", "missing path");
        String remote = (String) payload.getOrDefault("remote", "origin");
        String branch = (String) payload.getOrDefault("branch", "main");
        try {
            new ProcessBuilder("git", "-C", p, "merge", branch).inheritIO().start().waitFor();
            Process pushProc = new ProcessBuilder("git", "-C", p, "push", remote).inheritIO().start();
            return Map.of("ok", pushProc.waitFor() == 0);
        } catch (Exception e) {
            return Map.of("ok", false, "error", e.getMessage());
        }
    }

    private static Map<String, Object> triggerHpccJob(Collection.Node node, Map<String, Object> payload) {
        String p = node.path != null ? node.path : (String) payload.get("path");
        String script = (String) payload.getOrDefault("script", "job.sh");
        if (p == null) return Map.of("ok", false, "error", "missing path");
        try {
            Process proc = new ProcessBuilder("sbatch", Path.of(p, script).toString()).directory(Path.of(p).toFile()).inheritIO().start();
            return Map.of("ok", proc.waitFor() == 0);
        } catch (Exception e) {
            return Map.of("ok", false, "error", e.getMessage());
        }
    }

    private static Map<String, Object> triggerRunScript(Collection.Node node, Map<String, Object> payload) {
        String p = node.path != null ? node.path : (String) payload.get("path");
        String script = (String) payload.get("script");
        if (p == null || script == null) return Map.of("ok", false, "error", "missing path/script");
        try {
            Process proc = new ProcessBuilder().command("sh", "-c", script).directory(Path.of(p).toFile()).inheritIO().start();
            return Map.of("ok", proc.waitFor() == 0);
        } catch (Exception e) {
            return Map.of("ok", false, "error", e.getMessage());
        }
    }
}
