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

typedef void(^AKDMUpdateCompleteBlock)(BOOL result);
typedef void(^AKDMQueryCompleteBlock)(NSArray<NSDictionary *> *results);

@interface AKDatabaseManager : NSObject

+ (AKDatabaseManager *)managerWithDatabasePath:(NSString *)path;
+ (void)closeWithDatabasePath:(NSString *)path;

/**
 *  组装SQL语句
 *
 *  @param sql               基础SQL语句
 *  @param basicParams       Key-Value条件
 *  @param specifiedParams   指定条件
 *
 *  @return SQL语句
 */
+ (NSString *)makeSQL:(NSString *)sql 
          basicParams:(NSDictionary *)basicParams
      specifiedParams:(NSArray *)specifiedParams;

/**
 *  执行Update类型SQL语句
 *  当complete为nil的时候为同步执行，complete有值的情况下为异步执行
 *
 *  @param sql      SQL语句
 *  @param complete AKDMUpdateCompleteBlock，完成的block
 *
 *  @return BOOL    当complete!=nil的情况下总是返回NO
 */
- (BOOL)update:(NSString *)sql complete:(AKDMUpdateCompleteBlock)complete;

/**
 *  执行Query类型SQL语句
 *  当complete为nil的时候为同步执行，complete!=nil的情况下为异步执行
 *
 *  @param sql      SQL语句
 *  @param complete AKDMQueryCompleteBlock，完成的block
 *
 *  @return NSArray<NSDictionary *> 当complete!=nil的情况下总是返回nil
 */
- (NSArray<NSDictionary *> *)query:(NSString *)sql complete:(AKDMQueryCompleteBlock)complete;

/**
 *  检查并创建表
 *  支持数据库表安全升级
 *
 *  @param table  NSString 表名
 *  @param fields NSDictionary 列信息 <name, type&other>
 */
- (void)checkAndCreateTable:(NSString *)table fields:(NSDictionary *)fields;

@end

NS_ASSUME_NONNULL_END
