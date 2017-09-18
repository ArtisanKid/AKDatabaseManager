//
//  AKDatabaseManager.h
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#import <Foundation/Foundation.h>
#import "AKDatabase.h"

NS_ASSUME_NONNULL_BEGIN

@interface AKDatabaseManager : NSObject

@property (class, nonatomic, strong, readonly) AKDatabaseManager *manager;

@property (nonatomic, strong, readonly) NSDictionary<NSString */*TableName*/, AKDatabase *> *databases;

- (void)setDatabase:(AKDatabase *)database forIdentifier:(NSString *)identifier;
- (void)removeDatabase:(NSString *)identifier;
- (AKDatabase *)databaseWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
