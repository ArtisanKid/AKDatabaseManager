//
//  AKDatabaseTableColumn.m
//  Pods
//
//  Created by 李翔宇 on 2017/9/13.
//
//

#import "AKDatabaseTableColumn.h"

@implementation AKDatabaseTableColumn

- (instancetype)init {
    return [self initWithName:nil type:AKDatabaseTableColumnTypeNULL];
}

- (instancetype)initWithName:(NSString *)name type:(AKDatabaseTableColumnType)type {
    self = [super init];
    if(self) {
        self.name = name;
        self.type = type;
    }
    return self;
}

- (void)setType:(AKDatabaseTableColumnType)type {
    if(self.isAutoincrement) {
        return;
    }
    
    _type = type;
}

- (void)setPrimaryKey:(BOOL)primaryKey {
    if(self.isAutoincrement) {
        return;
    }
    
    _primaryKey = primaryKey;
}

- (void)setAutoincrement:(BOOL)autoincrement {
    _autoincrement = autoincrement;
    if(_autoincrement) {
        self->_type = AKDatabaseTableColumnTypeInteger;
        self->_primaryKey = YES;
        self->_notNull = NO;
        self->_defaultValue = nil;
    }
}

- (void)setNotNull:(BOOL)notNull {
    if(self.isAutoincrement) {
        return;
    }
    
    _notNull = notNull;
}

- (void)setDefaultValue:(NSString *)defaultValue {
    if(self.isAutoincrement) {
        return;
    }
    
    _defaultValue = defaultValue;
}

@end
