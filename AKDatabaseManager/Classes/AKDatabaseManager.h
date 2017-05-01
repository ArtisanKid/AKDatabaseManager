//
//  AKDatabaseManager.h
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#import <Foundation/Foundation.h>
#import <FMDB/FMResultSet.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AKUpdateComplete)(BOOL result);
typedef void(^AKQueryComplete)(NSArray<NSDictionary *> *results);

@interface AKDatabaseManager : NSObject

+ (AKDatabaseManager *)managerWithDatabasePath:(NSString *)path;
+ (void)closeWithDatabasePath:(NSString *)path;

/**
 组装SQL语句

 @param sql 基础SQL语句
 @param params Key-Value条件
 @param specifiedParams 指定条件，指定条件会由‘AND’进行连接
 @return SQL语句
 */
+ (NSString *)makeSQL:(NSString *)sql
               params:(NSDictionary *)params
      specifiedParams:(NSArray *)specifiedParams;

/**
 执行Update类型SQL语句
 当complete为nil的时候为同步执行，complete有值的情况下为异步执行

 @param sql SQL语句
 @param complete 完成的block
 @return 当complete!=nil的情况下总是返回NO
 */
- (BOOL)update:(NSString *)sql complete:(AKUpdateComplete)complete;

/**
 执行Query类型SQL语句
 当complete为nil的时候为同步执行，complete!=nil的情况下为异步执行

 @param sql SQL语句
 @param complete AKDMQueryCompleteBlock，完成的block
 @return NSArray<NSDictionary *> 当complete!=nil的情况下总是返回nil
 */
- (NSArray<NSDictionary *> *)query:(NSString *)sql complete:(AKQueryComplete)complete;

/**
 检查并创建表
 支持数据库表安全升级

 @param table 表名
 @param fields 列信息，{列名:类型&说明}
 */
- (void)checkAndCreateTable:(NSString *)table fields:(NSDictionary *)fields;

@end

NS_ASSUME_NONNULL_END
