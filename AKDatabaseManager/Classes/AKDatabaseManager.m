//
//  AKDatabaseManager.m
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#import "AKDatabaseManager.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import "AKDatabaseManagerMacro.h"

@interface AKDatabaseManager ()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

/**
 并行读写操作队列
 */
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

@end

@implementation AKDatabaseManager

static NSMutableDictionary *AKDatabaseManagerDicM() {
    static NSMutableDictionary<NSString *, AKDatabaseManager *> *managerDicM = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        managerDicM = [NSMutableDictionary dictionary];
    });
    return managerDicM;
}

/**
 并行读写操作队列
 */
static dispatch_queue_t AKDatabaseManagerConcurrentQueue() {
    static dispatch_queue_t concurrentQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *label = [NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".AKDatabaseManager"];
        concurrentQueue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    });
    return concurrentQueue;
}

+ (AKDatabaseManager *)managerWithDatabasePath:(NSString *)path {
    NSParameterAssert(path);
    if(!path.length) {
        return nil;
    }
    
    AKDatabaseManager *manager = AKDatabaseManagerDicM()[path];
    if(manager) {
        return manager;
    }
    
    manager = [[AKDatabaseManager alloc] init];
    manager.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    
    AKDatabaseManagerDicM()[path] = manager;
    
    return manager;
}

+ (void)closeWithDatabasePath:(NSString *)path {
    NSParameterAssert(path);
    if(!path.length) {
        return;
    }
    
    AKDatabaseManager *manager = AKDatabaseManagerDicM()[path];
    if(!manager) {
        return;
    }
    
    [manager.databaseQueue close];
    AKDatabaseManagerDicM()[path] = nil;
}

#pragma mark- 私有方法
- (BOOL)update:(NSString *)sql {
    __block BOOL canCommit = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        canCommit = [db executeUpdate:sql];
        if (!canCommit) {
            AKDatabaseManagerLog(@"数据库Update错误 Error:%@", db.lastError);
            *rollback = YES;
        }
    }];
    return canCommit;
}

- (NSArray<NSDictionary *> *)query:(NSString *)sql {
    //如果[set close];不在inDatabase的block中执行可能会造成EXC_BAD_ACCESS
    //出现的原因是Sqlite3不支持多线程访问未解除持有的connection（数据库连接）
    //[set close];才会将query当前持有的connection释放，
    //因此不执行[set close];可能会出现多线程访问inDatabase或者inTransaction的时候出现多线程访问connection
    //http://www.cnblogs.com/wfwenchao/p/3964213.html
    
    NSMutableArray<NSDictionary *> *resultsM = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:sql];
        if (set) {
            while ([set next]) {
                [resultsM addObject:[set resultDictionary]];
            }
        } else {
            AKDatabaseManagerLog(@"数据库查询错误 Error:%@", db.lastError);
        }
        [set close];
    }];
    return [resultsM copy];
}

#pragma mark- 公开方法
+ (NSString *)makeSQL:(NSString *)sql 
          basicParams:(NSDictionary *)basicParams
      specifiedParams:(NSArray *)specifiedParams {
    NSMutableString *mSQL = [NSMutableString stringWithString:sql];
    if (basicParams.allValues.count || specifiedParams.count) {
        [mSQL appendFormat:@" WHERE "];
    }
    
    for (NSString *key in basicParams.allKeys) {
        [mSQL appendFormat:@"%@ = '%@' AND ", key, basicParams[key]];
    }
    
    for (NSString *fragment in specifiedParams) {
        [mSQL appendFormat:@"%@ AND ", fragment];
    }
    
    if (basicParams.allValues.count || specifiedParams.count) {
        [mSQL appendString:@"1 = 1"];
    }
    
    AKDatabaseManagerLog(@"拼装得到的SQL语句:%@", mSQL);
    return mSQL;
}

- (BOOL)update:(NSString *)sql complete:(AKUpdateComplete)complete {
    if(complete) {
        dispatch_barrier_async(AKDatabaseManagerConcurrentQueue(), ^{
            BOOL canCommit = [self update:sql];
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(canCommit);
            });
        });
        return YES;
    } else {
        return [self update:sql];
    }
}

- (NSArray<NSDictionary *> *)query:(NSString *)sql complete:(AKQueryComplete)complete {
    if(complete) {
        dispatch_async(AKDatabaseManagerConcurrentQueue(), ^{
            NSArray<NSDictionary *> *results = [self query:sql];
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(results);
            });
        });
        return nil;
    } else {
        return [self query:sql];
    }
}

- (BOOL)createTable:(NSString *)table fields:(NSDictionary *)fields {
    NSMutableString *createSQL = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", table];
    NSMutableArray *fieldsM = [NSMutableArray array];
    for(NSString *key in fields.allKeys) {
        [fieldsM addObject:[NSString stringWithFormat:@"%@ %@", key, fields[key]]];
    }
    [createSQL appendString:[fieldsM componentsJoinedByString:@","]];
    [createSQL appendString:@")"];
    return [self update:createSQL];
}

- (void)checkAndCreateTable:(NSString *)table fields:(NSDictionary *)fields  {
    [self createTable:table fields:fields];
    
    NSString *identifier = [fields.allKeys componentsJoinedByString:@"%%"];
    NSString *fieldsCheckSQL = [NSString stringWithFormat:@"SELECT * FROM sqlite_master WHERE sql LIKE 'CREATE TABLE %%%@%%%@%%'", table, identifier];
    BOOL result = [self update:fieldsCheckSQL];
    if(!result) {
        NSString *dropSQL = [NSString stringWithFormat:@"DROP TABLE %@", table];
        [self update:dropSQL];
        [self createTable:table fields:fields];
    }
}

@end
