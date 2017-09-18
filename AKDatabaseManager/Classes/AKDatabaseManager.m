//
//  AKDatabaseManager.m
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#import "AKDatabaseManager.h"

@interface AKDatabaseManager()

@property (nonatomic, strong) NSMutableDictionary<NSString *, AKDatabase *> *databasesM;

@end

@implementation AKDatabaseManager

+ (AKDatabaseManager *)manager {
    static AKDatabaseManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    return sharedInstance;
}

+ (id)alloc {
    return [self manager];
}

+ (id)allocWithZone:(NSZone * _Nullable)zone {
    return [self manager];
}

- (id)copy {
    return self;
}

- (id)copyWithZone:(NSZone * _Nullable)zone {
    return self;
}

- (NSDictionary<NSString */*TableName*/, AKDatabase *> *)databases {
    return [self.databasesM copy];
}

- (void)setDatabase:(AKDatabase *)database forIdentifier:(NSString *)identifier {
    self.databasesM[identifier] = database;
}

- (void)removeDatabase:(NSString *)identifier {
    [self.databasesM removeObjectForKey:identifier];
}

- (AKDatabase *)databaseWithIdentifier:(NSString *)identifier {
    return self.databasesM[identifier];
}

- (NSMutableDictionary<NSString *, AKDatabase *> *)databasesM {
    if(_databasesM) {
        return _databasesM;
    }
    
    _databasesM = [NSMutableDictionary dictionary];
    return _databasesM;
}

@end
