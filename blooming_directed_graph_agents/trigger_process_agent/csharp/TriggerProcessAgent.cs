using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace BloomingDirectedGraphTriggerProcessAgent;

/// <summary>blooming_directed_graph_trigger_process_agent – C#. IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md</summary>
public static class TriggerProcessAgent
{
    public static async Task<Dictionary<string, object>> TriggerAsync(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        string action,
        Dictionary<string, object>? payload = null)
    {
        payload ??= new Dictionary<string, object>();
        return action switch
        {
            "workflow_dispatch" => await TriggerWorkflowDispatchAsync(node, payload),
            "git_push" => TriggerGit(node, "push", payload),
            "git_fetch" => TriggerGit(node, "fetch", payload),
            "fetch_merge" => TriggerFetchMerge(node, payload),
            "push_merge" => TriggerPushMerge(node, payload),
            "pull_merge" => TriggerGit(node, "pull", payload),
            "job_submit" => TriggerHpccJob(node, payload),
            "run_script" => TriggerRunScript(node, payload),
            "notify" => new Dictionary<string, object> { ["ok"] = true, ["message"] = "notify not implemented" },
            _ => new Dictionary<string, object> { ["ok"] = false, ["error"] = "unknown action: " + action }
        };
    }

    static async Task<Dictionary<string, object>> TriggerWorkflowDispatchAsync(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        Dictionary<string, object> payload)
    {
        var owner = (payload.TryGetValue("owner", out var o) ? o : null) as string ?? node.Owner;
        var repo = (payload.TryGetValue("repo", out var r) ? r : null) as string ?? node.Repo ?? node.Slug;
        var workflowId = (payload.TryGetValue("workflow_id", out var w) ? w : null) as string;
        var refBranch = (payload.TryGetValue("ref", out var rf) ? rf : null) as string ?? "main";
        if (string.IsNullOrEmpty(owner) || string.IsNullOrEmpty(repo) || string.IsNullOrEmpty(workflowId))
            return new Dictionary<string, object> { ["ok"] = false, ["error"] = "missing owner/repo/workflow_id" };
        var token = Environment.GetEnvironmentVariable("GITHUB_TOKEN");
        if (string.IsNullOrEmpty(token))
            return new Dictionary<string, object> { ["ok"] = false, ["error"] = "GITHUB_TOKEN not set" };
        using var client = new HttpClient();
        client.DefaultRequestHeaders.Add("Accept", "application/vnd.github.v3+json");
        client.DefaultRequestHeaders.Add("Authorization", "Bearer " + token);
        var body = JsonSerializer.Serialize(new { ref = refBranch });
        var res = await client.PostAsync(
            $"https://api.github.com/repos/{owner}/{repo}/actions/workflows/{workflowId}/dispatches",
            new StringContent(body, System.Text.Encoding.UTF8, "application/json"));
        return new Dictionary<string, object> { ["ok"] = res.IsSuccessStatusCode };
    }

    static Dictionary<string, object> TriggerGit(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        string cmd,
        Dictionary<string, object> payload)
    {
        var p = node.Path ?? (payload.TryGetValue("path", out var px) ? px : null) as string;
        if (string.IsNullOrEmpty(p) || !Directory.Exists(p))
            return new Dictionary<string, object> { ["ok"] = false, ["error"] = "missing path" };
        var proc = Process.Start(new ProcessStartInfo("git", $"-C \"{p}\" {cmd}") { UseShellExecute = false });
        proc?.WaitForExit();
        return new Dictionary<string, object> { ["ok"] = proc?.ExitCode == 0 };
    }

    static Dictionary<string, object> TriggerFetchMerge(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        Dictionary<string, object> payload)
    {
        var p = node.Path ?? (payload.TryGetValue("path", out var px) ? px : null) as string;
        if (string.IsNullOrEmpty(p) || !Directory.Exists(p))
            return new Dictionary<string, object> { ["ok"] = false, ["error"] = "missing path" };
        var remote = (payload.TryGetValue("remote", out var r) ? r : null) as string ?? "origin";
        var branch = (payload.TryGetValue("branch", out var b) ? b : null) as string ?? "main";
        var proc1 = Process.Start(new ProcessStartInfo("git", $"-C \"{p}\" fetch {remote}") { UseShellExecute = false });
        if (proc1?.WaitForExit() != true || proc1.ExitCode != 0)
            return new Dictionary<string, object> { ["ok"] = false };
        var proc2 = Process.Start(new ProcessStartInfo("git", $"-C \"{p}\" merge {remote}/{branch}") { UseShellExecute = false });
        proc2?.WaitForExit();
        return new Dictionary<string, object> { ["ok"] = proc2?.ExitCode == 0 };
    }

    static Dictionary<string, object> TriggerPushMerge(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        Dictionary<string, object> payload)
    {
        var p = node.Path ?? (payload.TryGetValue("path", out var px) ? px : null) as string;
        if (string.IsNullOrEmpty(p) || !Directory.Exists(p))
            return new Dictionary<string, object> { ["ok"] = false, ["error"] = "missing path" };
        var remote = (payload.TryGetValue("remote", out var r) ? r : null) as string ?? "origin";
        var branch = (payload.TryGetValue("branch", out var b) ? b : null) as string ?? "main";
        try
        {
            var proc1 = Process.Start(new ProcessStartInfo("git", $"-C \"{p}\" merge {branch}") { UseShellExecute = false });
            proc1?.WaitForExit();
            var proc2 = Process.Start(new ProcessStartInfo("git", $"-C \"{p}\" push {remote}") { UseShellExecute = false });
            proc2?.WaitForExit();
            return new Dictionary<string, object> { ["ok"] = proc2?.ExitCode == 0 };
        }
        catch { return new Dictionary<string, object> { ["ok"] = false }; }
    }

    static Dictionary<string, object> TriggerHpccJob(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        Dictionary<string, object> payload)
    {
        var p = node.Path ?? (payload.TryGetValue("path", out var px) ? px : null) as string;
        var script = (payload.TryGetValue("script", out var sx) ? sx : null) as string ?? "job.sh";
        if (string.IsNullOrEmpty(p)) return new Dictionary<string, object> { ["ok"] = false, ["error"] = "missing path" };
        var proc = Process.Start(new ProcessStartInfo("sbatch", Path.Combine(p, script)) { WorkingDirectory = p, UseShellExecute = false });
        proc?.WaitForExit();
        return new Dictionary<string, object> { ["ok"] = proc?.ExitCode == 0 };
    }

    static Dictionary<string, object> TriggerRunScript(
        BloomingDirectedGraphFilterAgents.Collection.Node node,
        Dictionary<string, object> payload)
    {
        var p = node.Path ?? (payload.TryGetValue("path", out var px) ? px : null) as string;
        var script = (payload.TryGetValue("script", out var sx) ? sx : null) as string;
        if (string.IsNullOrEmpty(p) || string.IsNullOrEmpty(script))
            return new Dictionary<string, object> { ["ok"] = false, ["error"] = "missing path/script" };
        var proc = Process.Start(new ProcessStartInfo("sh", "-c", script) { WorkingDirectory = p, UseShellExecute = false });
        proc?.WaitForExit();
        return new Dictionary<string, object> { ["ok"] = proc?.ExitCode == 0 };
    }
}
