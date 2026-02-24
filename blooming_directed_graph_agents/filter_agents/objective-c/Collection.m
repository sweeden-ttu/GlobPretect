// blooming_directed_graph_filter_agents – Objective-C collection implementation.
#import "Collection.h"

@implementation BDGNode
@end

@implementation BloomingDirectedGraphFilterAgents
+ (NSArray<BDGNode *> *)filterByReceiver:(NSArray<BDGNode *> *)nodes receiver:(NSString *)receiver {
    if (![receiver isEqualToString:@"github"] && ![receiver isEqualToString:@"hpcc"]) return nodes;
    return [nodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(BDGNode *n, id _) {
        return n.owner.length && n.repo.length;
    }]];
}
+ (NSArray<BDGNode *> *)filterByActionWhere:(NSArray<BDGNode *> *)nodes where:(NSString *)where {
    if (![where isEqualToString:@"github"] && ![where isEqualToString:@"hpcc"]) return nodes;
    return [nodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(BDGNode *n, id _) {
        if ([where isEqualToString:@"github"]) return [n.name containsString:@"github"];
        return [n.name.lowercaseString containsString:@"hpcc"];
    }]];
}
+ (NSArray<BDGNode *> *)filterByActionClient:(NSArray<BDGNode *> *)nodes client:(NSString *)client {
    if (![client isEqualToString:@"macbook"] && ![client isEqualToString:@"rockydesktop"]) return nodes;
    return [nodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(BDGNode *n, id _) {
        if ([client isEqualToString:@"macbook"]) return [n.name containsString:@"owner"];
        return [n.name containsString:@"quay"];
    }]];
}
+ (NSArray<BDGNode *> *)filterByRepoName:(NSArray<BDGNode *> *)nodes pattern:(NSString *)pattern {
    return [nodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(BDGNode *n, id _) {
        return [n.name containsString:pattern];
    }]];
}
@end
