//
//  AKDatabaseTableColumn.h
//  Pods
//
//  Created by 李翔宇 on 2017/9/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AKDatabaseTableColumnType) {
    AKDatabaseTableColumnTypeNULL,
    AKDatabaseTableColumnTypeInteger, //INTEGER
    AKDatabaseTableColumnTypeReal, //REAL
    AKDatabaseTableColumnTypeText, //TEXT
    AKDatabaseTableColumnTypeBlob //BLOB
};

@interface AKDatabaseTableColumn : NSObject

- (instancetype)initWithName:(NSString *)name type:(AKDatabaseTableColumnType)type NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) AKDatabaseTableColumnType type;
@property (nonatomic, assign, getter=isPrimaryKey) BOOL primaryKey; //PRIMARY KEY
@property (nonatomic, assign, getter=isAutoincrement) BOOL autoincrement; //AUTOINCREMENT
@property (nonatomic, assign, getter=isNotNull) BOOL notNull; //NOT NULL

/**
 当前仅支持字符串默认值
 */
@property (nonatomic, strong) NSString *defaultValue; //DEFAULT

@end
