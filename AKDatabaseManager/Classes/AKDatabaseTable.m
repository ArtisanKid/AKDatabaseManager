//
//  AKDatabaseTable.m
//  Pods
//
//  Created by 李翔宇 on 2017/9/13.
//
//

#import "AKDatabaseTable.h"

@implementation AKDatabaseTable

- (instancetype)init {
    return [self initWithName:nil columns:nil];
}

- (instancetype)initWithName:(NSString *)name columns:(NSArray<AKDatabaseTableColumn *> *)columns {
    self = [super init];
    if(self) {
        self.name = name;
        self.columns = columns;
    }
    return self;
}

@end
