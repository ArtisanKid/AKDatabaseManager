//
//  AKDatabase.h
//  Pods
//
//  Created by 李翔宇 on 2017/3/7.
//
//

#import <Foundation/Foundation.h>
#import "AKDatabaseTable.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain AKDatabaseErrorDomain;
FOUNDATION_EXTERN NSErrorDomain AKDatabaseErrorMessageKey;

@class AKDatabase;

typedef void(^AKDatabaseQuerySuccess)(NSArray<NSDictionary *> *results);
typedef void(^AKDatabaseSuccess)(BOOL result);
typedef void(^AKDatabaseFailure)(NSError *error);
typedef void(^AKDatabaseTransaction)(AKDatabase *db, BOOL *shouldRollback);

@interface AKDatabase : NSObject

@property (nonatomic, assign, getter=isDebug) BOOL debug;

+ (AKDatabase *)dataWithPath:(NSString *)path;

@property (nonatomic, strong) NSString *path;

/**
 打开数据库连接

 @param error 错误
 @return 打开结果
 */
- (BOOL)open:(NSError **)error;

@property (nonatomic, assign, getter=isHadOpen, readonly) BOOL hadOpen;/**<打开状态*/

/**
 关闭数据库连接

 @param error 错误
 @return 关闭结果
 */
- (BOOL)close:(NSError **)error;

/**
 执行Update类型SQL语句
 当success为nil的时候为同步执行，success有值的情况下为异步执行
 
 @param sql SQL语句
 @param success 成功的block
 @param failure 失败的block
 @return 当success!=nil的情况下总是返回NO
 */
- (BOOL)update:(NSString *)sql
       success:(AKDatabaseSuccess _Nullable)success
       failure:(AKDatabaseFailure _Nullable)failure;

/**
 执行Query类型SQL语句
 当success为nil的时候为同步执行，success!=nil的情况下为异步执行
 
 @param sql SQL语句
 @param success 成功的block
 @param failure 失败的block
 @return NSArray<NSDictionary *> 当complete!=nil的情况下总是返回nil
 */
- (NSArray<NSDictionary *> *)query:(NSString *)sql
                           success:(AKDatabaseQuerySuccess _Nullable)success
                           failure:(AKDatabaseFailure _Nullable)failure;

/**
 事务
 当success为nil的时候为同步执行，success!=nil的情况下为异步执行
 
 @param transaction 事务的block
 @param useDeferred 是否deferred模式
 @param success 成功的block
 @param failure 失败的block
 @return 当success!=nil的情况下总是返回NO
 */
- (BOOL)inTransaction:(AKDatabaseTransaction)transaction
             deferred:(BOOL)useDeferred
              success:(AKDatabaseSuccess _Nullable)success
              failure:(AKDatabaseFailure _Nullable)failure;

/**
 创建表

 @param table AKDatabaseTable
 @param policy 创建策略
 @param error 错误
 @return 创建结果
 */
- (BOOL)createTable:(AKDatabaseTable *)table policy:(AKDatabaseTableCreatePolicy)policy error:(NSError **)error;

/**
 删除表

 @param name 表名
 @param error 错误
 @return 删除结果
 */
- (BOOL)deleteTable:(NSString *)name error:(NSError **)error;

/**
 清空表

 @param name 表名
 @param forceReset 强制重置。YES则使用Truncate，NO则使用Delete
 @param error 错误
 @return 删除结果
 */
- (BOOL)emptyTable:(NSString *)name forceReset:(BOOL)forceReset error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
