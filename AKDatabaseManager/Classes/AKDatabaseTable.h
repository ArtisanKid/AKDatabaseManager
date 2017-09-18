//
//  AKDatabaseTable.h
//  Pods
//
//  Created by 李翔宇 on 2017/9/13.
//
//

#import <Foundation/Foundation.h>
#import "AKDatabaseTableColumn.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AKDatabaseTableCreatePolicy) {
    AKDatabaseTableCreateDefault, //有则停止，没有则创建
    AKDatabaseTableCreateMigrate, //原有数据库表更改名称，然后重新创建，之后迁移数据
    AKDatabaseTableCreateForce //原有数据库表删除，然后重新创建
};

@interface AKDatabaseTable : NSObject

- (instancetype)initWithName:(NSString *)name columns:(NSArray<AKDatabaseTableColumn *> *)columns NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<AKDatabaseTableColumn *> *columns;

@end

NS_ASSUME_NONNULL_END
