// blooming_directed_graph_trigger_process_agent – Objective-C implementation.
// IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
#import "TriggerProcessAgent.h"
#import "Collection.h"  // from filter_agents/objective-c; add -I when building
#import <stdlib.h>

@implementation BloomingDirectedGraphTriggerProcessAgent
+ (NSDictionary *)triggerWithNode:(BDGNode *)node action:(NSString *)action payload:(NSDictionary *)payload {
    if ([action isEqualToString:@"workflow_dispatch"]) {
        return @{ @"ok": @(YES) };
    }
    if ([action isEqualToString:@"git_push"] || [action isEqualToString:@"git_fetch"]) {
        NSString *cmd = [action isEqualToString:@"git_push"] ? @"push" : @"fetch";
        int r = system([[NSString stringWithFormat:@"git -C \"%@\" %@", node.path, cmd] UTF8String]);
        return @{ @"ok": @(r == 0) };
    }
    if ([action isEqualToString:@"fetch_merge"]) {
        NSString *remote = payload[@"remote"] ?: @"origin";
        NSString *branch = payload[@"branch"] ?: @"main";
        NSString *cmd = [NSString stringWithFormat:@"git -C \"%@\" fetch %@ && git -C \"%@\" merge %@/%@", node.path, remote, node.path, remote, branch];
        int r = system([cmd UTF8String]);
        return @{ @"ok": @(r == 0) };
    }
    if ([action isEqualToString:@"push_merge"]) {
        NSString *remote = payload[@"remote"] ?: @"origin";
        NSString *branch = payload[@"branch"] ?: @"main";
        NSString *cmd = [NSString stringWithFormat:@"(cd \"%@\" && git merge %@ 2>/dev/null; git push %@)", node.path, branch, remote];
        int r = system([cmd UTF8String]);
        return @{ @"ok": @(r == 0) };
    }
    if ([action isEqualToString:@"pull_merge"]) {
        NSString *remote = payload[@"remote"] ?: @"origin";
        NSString *branch = payload[@"branch"] ?: @"main";
        NSString *cmd = [NSString stringWithFormat:@"git -C \"%@\" pull %@ %@", node.path, remote, branch];
        int r = system([cmd UTF8String]);
        return @{ @"ok": @(r == 0) };
    }
    if ([action isEqualToString:@"job_submit"]) {
        NSString *script = payload[@"script"] ?: @"job.sh";
        NSString *cmd = [NSString stringWithFormat:@"cd \"%@\" && sbatch \"%@\"", node.path, script];
        int r = system([cmd UTF8String]);
        return @{ @"ok": @(r == 0) };
    }
    if ([action isEqualToString:@"notify"]) {
        return @{ @"ok": @(YES), @"message": @"notify not implemented" };
    }
    return @{ @"ok": @(NO), @"error": [NSString stringWithFormat:@"unknown action: %@", action] };
}
@end
