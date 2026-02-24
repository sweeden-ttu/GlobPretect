// blooming_directed_graph_filter_agents – Objective-C collection.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDGNode : NSObject
@property (copy) NSString *name;
@property (copy) NSString *path;
@property (copy, nullable) NSString *owner;
@property (copy, nullable) NSString *repo;
@property (copy) NSString *slug;
@end

@interface BloomingDirectedGraphFilterAgents : NSObject
+ (NSArray<BDGNode *> *)filterByReceiver:(NSArray<BDGNode *> *)nodes receiver:(NSString *)receiver;
+ (NSArray<BDGNode *> *)filterByActionWhere:(NSArray<BDGNode *> *)nodes where:(NSString *)where;
+ (NSArray<BDGNode *> *)filterByActionClient:(NSArray<BDGNode *> *)nodes client:(NSString *)client;
+ (NSArray<BDGNode *> *)filterByRepoName:(NSArray<BDGNode *> *)nodes pattern:(NSString *)pattern;
@end

NS_ASSUME_NONNULL_END
