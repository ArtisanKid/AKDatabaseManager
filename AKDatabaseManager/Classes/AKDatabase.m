//
//  AKDatabase.m
//  Pods
//
//  Created by 李翔宇 on 2017/3/7.
//
//

#import "AKDatabase.h"
#import <sqlite3.h>
#import <FMDB/FMDatabase.h>
#import "AKDatabaseConstants.h"
#import "AKDatabaseManagerMacros.h"
#include "AKDatabaseManager.h"

NSErrorDomain AKDatabaseErrorDomain = @"AKDatabaseErrorDomain";
NSErrorDomain AKDatabaseErrorMessageKey = @"AKDatabaseErrorMessageKey";

NSErrorDomain AKDatabaseTableStructureColumnNameKey = @"name";
NSErrorDomain AKDatabaseTableStructureColumnTypeKey = @"type";
NSErrorDomain AKDatabaseTableStructureColumnPrimaryKey = @"pk";
NSErrorDomain AKDatabaseTableStructureColumnNotNullKey = @"notnull";
NSErrorDomain AKDatabaseTableStructureColumnDefaultValueKey = @"dflt_value";//默认值

@interface AKDatabase ()

/**
 当操作不在主线程时，需要用信号量将操作串行化
 */
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t write_serial_queue;
@property (nonatomic, strong) dispatch_queue_t read_serial_queue;
@property (nonatomic, strong) FMDatabase *readDatabase;
@property (nonatomic, strong) FMDatabase *writeDatabase;
@property (nonatomic, assign, getter=isHadOpen) BOOL hadOpen;

@end

@implementation AKDatabase

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int mode = sqlite3_threadsafe();
        if(mode == SQLITE_CONFIG_SINGLETHREAD) {
            AKDatabaseManagerLog(@"单线程模式");
        } else if(mode == SQLITE_CONFIG_MULTITHREAD) {
            AKDatabaseManagerLog(@"多线程模式");
        } else if(mode == SQLITE_CONFIG_SERIALIZED) {
            AKDatabaseManagerLog(@"序列化模式");
        }
        
        /**
         关闭内存统计，防止多线程访问造成阻塞
         具体参考：https://wereadteam.github.io/2016/08/19/SQLite/
         */
        if(sqlite3_config(SQLITE_CONFIG_MEMSTATUS, 0) != SQLITE_OK) {
            if(AKDatabase.isDebug) {
                AKDatabaseManagerLog(@"数据库配置失败");
            }
        }
    });
}

static BOOL AKDatabaseDebug = NO;
+ (void)setDebug:(BOOL)debug {
    AKDatabaseDebug = debug;
}
+ (BOOL)isDebug {
    return AKDatabaseDebug;
}

+ (NSString *)identifierWithPath:(NSString *)path {
    return [NSString stringWithFormat:@"%@", @(path.hash)];
}

- (void)dealloc {
    [self close:nil];
}

+ (AKDatabase *)dataWithPath:(NSString *)path {
    NSString *identifier = [self identifierWithPath:path];
    AKDatabase *database = AKDatabaseManager.manager.databases[identifier];
    if(!database) {
        database = [[AKDatabase alloc] init];
        
        database.path = path;
        database.semaphore = dispatch_semaphore_create(1);
        
        NSString *date = [NSString stringWithFormat:@"%@", @((NSUInteger)(NSDate.date.timeIntervalSince1970 * 1000))];
        NSString *queue_label = [NSBundle.mainBundle.bundleIdentifier stringByAppendingFormat:@".%@.%@.%@", NSStringFromClass([self class]), identifier, date];
        if(NSProcessInfo.processInfo.activeProcessorCount > 1) {
            const char *read_queue_label = [queue_label stringByAppendingString:@".read"].UTF8String;
            dispatch_queue_attr_t user_interactive_attr =  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
            database.read_serial_queue = dispatch_queue_create(read_queue_label, user_interactive_attr);
            
            const char *write_queue_label = [queue_label stringByAppendingString:@".write"].UTF8String;
            dispatch_queue_attr_t background_attr =  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0);
            database.write_serial_queue = dispatch_queue_create(write_queue_label, background_attr);
        } else {
            dispatch_queue_t serial_queue = dispatch_queue_create(queue_label.UTF8String, DISPATCH_QUEUE_SERIAL);
            database.read_serial_queue = serial_queue;
            database.write_serial_queue = serial_queue;
        }
    }
    return database;
}

- (void)setPath:(NSString *)path {
    if(self.readDatabase && self.writeDatabase) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库已连接，不可重复设置路径");
        }
        return;
    }
    
    _path = path;
}

- (BOOL)open:(NSError **)error {
    if(self.isHadOpen) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库已连接，无需重复连接");
        }
        return YES;
    }
    
    if(!self.path.length) {
        *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                     code:AKDatabaseErrorCodeParamLack
                                 userInfo:@{AKDatabaseErrorMessageKey : @"未找到数据库"}];
        return NO;
    }
    
    if(!self.readDatabase && !self.writeDatabase) {
        FMDatabase *readDatabase = [[FMDatabase alloc] initWithPath:self.path];
        FMDatabase *writeDatabase = [[FMDatabase alloc] initWithPath:self.path];
#if DEBUG
        readDatabase.traceExecution = YES;
        readDatabase.checkedOut = YES;
        readDatabase.crashOnErrors = YES;
        readDatabase.logsErrors = YES;
        
        writeDatabase.traceExecution = YES;
        writeDatabase.checkedOut = YES;
        writeDatabase.crashOnErrors = YES;
        writeDatabase.logsErrors = YES;
#else
        readDatabase.traceExecution = NO;
        readDatabase.checkedOut = NO;
        readDatabase.crashOnErrors = NO;
        readDatabase.logsErrors = NO;
        
        writeDatabase.traceExecution = NO;
        writeDatabase.checkedOut = NO;
        writeDatabase.crashOnErrors = NO;
        writeDatabase.logsErrors = NO;
#endif
        self.readDatabase = readDatabase;
        self.writeDatabase = writeDatabase;
    }
    
    self.hadOpen = [self.readDatabase open] && [self.writeDatabase open];
    
    if(!self.isHadOpen) {
        if(self.readDatabase.lastError) {
            *error = self.readDatabase.lastError;
        }
        
        if(self.writeDatabase.lastError) {
            *error = self.writeDatabase.lastError;
        }
        
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库连接失败\n%@", *error);
        }
        
        self.readDatabase = nil;
        self.writeDatabase = nil;
    }
    
    [AKDatabaseManager.manager setDatabase:self forIdentifier:[AKDatabase identifierWithPath:self.path]];
    
    return self.isHadOpen;
}

- (BOOL)close:(NSError **)error {
    if(!self.isHadOpen) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库未连接，无需关闭");
        }
        return YES;
    }
    
    if(!self.readDatabase && !self.writeDatabase) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库未创建，无需关闭");
        }
        return YES;
    }
    
    if(![self.readDatabase close] || ![self.writeDatabase close]) {
        if(self.readDatabase.lastError) {
            *error = self.readDatabase.lastError;
        }
        
        if(self.writeDatabase.lastError) {
            *error = self.writeDatabase.lastError;
        }
        
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库关闭失败\n%@", *error);
        }
        
        return NO;
    }
    
    self.hadOpen = NO;
    
    return YES;
}

- (BOOL)update:(NSString *)sql
       success:(AKDatabaseSuccess)success
       failure:(AKDatabaseFailure)failure {
    if(![sql isKindOfClass:[NSString class]]) {
        NSError *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                             code:AKDatabaseErrorCodeParamTypeError
                                         userInfo:@{AKDatabaseErrorMessageKey : @"SQL语句类型错误"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"SQL语句类型错误");
        }
        !failure ? : failure(error);
        return NO;
    }
    
    if(!sql.length) {
        NSError *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                             code:AKDatabaseErrorCodeParamTypeError
                                         userInfo:@{AKDatabaseErrorMessageKey : @"SQL语句长度不能为0"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"SQL语句长度不能为0");
        }
        !failure ? : failure(error);
        return NO;
    }
    
    __block BOOL result = NO;
    void (^method)() = ^{
        result = [self.writeDatabase executeUpdate:sql];
        if(result) {
            !success ? : success(result);
        } else {
            !failure ? : failure(self.writeDatabase.lastError);
        }
    };

    if ([self.writeDatabase inTransaction]) {
        method();
    } else {
        if(success) {
            dispatch_async(self.write_serial_queue, ^{
                method();
            });
        } else {
            dispatch_sync(self.write_serial_queue, ^{
                method();
            });
        }
    }
    return result;
}

- (NSArray<NSDictionary *> *)query:(NSString *)sql
                           success:(AKDatabaseQuerySuccess)success
                           failure:(AKDatabaseFailure)failure {
    if(![sql isKindOfClass:[NSString class]]) {
        NSError *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                             code:AKDatabaseErrorCodeParamTypeError
                                         userInfo:@{AKDatabaseErrorMessageKey : @"SQL语句类型错误"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"SQL语句类型错误");
        }
        !failure ? : failure(error);
        return nil;
    }
    
    if(!sql.length) {
        NSError *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                             code:AKDatabaseErrorCodeParamTypeError
                                         userInfo:@{AKDatabaseErrorMessageKey : @"SQL语句长度不能为0"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"SQL语句长度不能为0");
        }
        !failure ? : failure(error);
        return nil;
    }
    
    __block NSArray<NSDictionary *> *results = nil;
    void (^method)() = ^{
        FMResultSet *set = [self.writeDatabase executeQuery:sql];
        NSError *transitionError = nil;
        results = [self resultsFromSet:set error:&transitionError];
        [set close];
        
        if(results) {
            !success ? : success(results);
        } else {
            !failure ? : failure(transitionError);
        }
    };
    
    if ([self checkCurrentQueueIsWriteSerialQueue]) {
        method();
    } else {
        if(success) {
            dispatch_async(self.read_serial_queue, ^{
                method();
            });
        } else {
            dispatch_sync(self.read_serial_queue, ^{
                method();
            });
        }
    }
    return results;
}

- (BOOL)inTransaction:(AKDatabaseTransaction)transaction
             deferred:(BOOL)useDeferred
              success:(AKDatabaseSuccess)success
              failure:(AKDatabaseFailure)failure {
    __block BOOL result = NO;
    void (^block)() = ^{
        if (useDeferred) {
            result = [self.writeDatabase beginDeferredTransaction];
            if(!result) {
                if(AKDatabase.isDebug) {
                    AKDatabaseManagerLog(@"Deferred事务开始失败\n%@", self.database.lastError);
                }
            }
        } else {
            result = [self.writeDatabase beginTransaction];
            if(!result) {
                if(AKDatabase.isDebug) {
                    AKDatabaseManagerLog(@"事务开始失败\n%@", self.database.lastError);
                }
            }
        }
        
        if(!result) {
            !failure ? : failure(self.writeDatabase.lastError);
            return;
        }
        
        BOOL shouldRollback = NO;
        transaction(self, &shouldRollback);
        
        if (shouldRollback) {
            if(AKDatabase.isDebug) {
                AKDatabaseManagerLog(@"事务回滚");
            }
            [self.writeDatabase rollback];
            result = NO;
        } else {
            result = [self.writeDatabase commit];
            if(!result) {
                if(AKDatabase.isDebug) {
                    AKDatabaseManagerLog(@"事务提交失败");
                }
            }
        }
        
        if(!result) {
            !failure ? : failure(self.writeDatabase.lastError);
            return;
        }
    };
    
    if(success) {
        dispatch_async(self.write_serial_queue, ^{
            block();
        });
    } else {
        dispatch_sync(self.write_serial_queue, ^{
            block();
        });
    }
    return result;
}

- (BOOL)createTable:(AKDatabaseTable *)table policy:(AKDatabaseTableCreatePolicy)policy error:(NSError **)error {
    if(!table.name.length) {
        *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                     code:AKDatabaseErrorCodeParamError
                                 userInfo:@{AKDatabaseErrorMessageKey : @"数据库表没有名称"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库表没有名称");
        }
        return NO;
    }
    
    if(!table.columns.count) {
        *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                     code:AKDatabaseErrorCodeParamError
                                 userInfo:@{AKDatabaseErrorMessageKey : @"数据库表中没有列信息"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库表中没有列信息");
        }
        return NO;
    }
    
    for(AKDatabaseTableColumn *column in table.columns) {
        if([column isKindOfClass:[AKDatabaseTableColumn class]]) {
            continue;
        }
        
        *error = [NSError errorWithDomain:AKDatabaseErrorDomain
                                     code:AKDatabaseErrorCodeParamTypeError
                                 userInfo:@{AKDatabaseErrorMessageKey : @"数据库表中列信息错误"}];
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"数据库表中列信息错误");
        }
        return NO;
    }
    
    BOOL hasExist = [self checkTableExist:table.name error:error];
    if(!hasExist) {
        BOOL result = [self createTable:table error:error];
        return result;
    }
    
    BOOL sameStructure = [self checkTableStructure:table error:error];
    if(sameStructure) {
        return YES;
    }
    
    BOOL result = [self inTransaction:^(AKDatabase * _Nonnull db, BOOL * _Nonnull shouldRollback) {
        switch (policy) {
            case AKDatabaseTableCreateDefault: {
                if(hasExist) {
                    if(AKDatabase.isDebug) {
                        AKDatabaseManagerLog(@"创建表失败，已有表");
                    }
                }
                break;
            }
                
            case AKDatabaseTableCreateMigrate: {
                NSString *migrateTableName = [table.name stringByAppendingFormat:@"%@", @((NSUInteger)(NSDate.date.timeIntervalSince1970 * 1000))];
                
                BOOL result = [self alterTable:table.name newTableName:migrateTableName error:error];
                if(!result) {
                    *shouldRollback = YES;
                    return;
                }
                
                result = [self createTable:table error:error];
                if(!result) {
                    *shouldRollback = YES;
                    return;
                }
                
                result = [self migrateTable:migrateTableName toTable:table.name error:error];
                if(!result) {
                    *shouldRollback = YES;
                    return;
                }
                
                result = [self deleteTable:migrateTableName error:error];
                if(!result) {
                    *shouldRollback = YES;
                }
                
                break;
            }
                
            case AKDatabaseTableCreateForce: {
                BOOL result = [self deleteTable:table.name error:error];
                if(!result) {
                    *shouldRollback = YES;
                    return;
                }
                
                result = [self createTable:table error:error];
                if(!result) {
                    *shouldRollback = YES;
                }
                
                break;
            }
                
            default:
                AKDatabaseManagerLog(@"WHAT THE FUCK");
                *shouldRollback = YES;
                break;
        }
    } deferred:YES success:nil failure:^(NSError * _Nonnull error) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"创建表失败\n%@", error);
        }
    }];
    return result;
}

- (BOOL)checkCurrentQueueIsWriteSerialQueue {
    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    if (strcmp(label, dispatch_queue_get_label(self.write_serial_queue)) == 0) {
        return YES;
    }
    return NO;
}

- (NSArray<NSDictionary *> *)resultsFromSet:(FMResultSet *)set error:(NSError **)error {
    NSMutableArray *resultsM = [NSMutableArray array];
    while ([set nextWithError:error]) {
        if(*error) {
            return nil;
        }
        [resultsM addObject:set.resultDictionary];
    }
    return [resultsM copy];
}

- (BOOL)checkTableExist:(NSString *)tableName error:(NSError **)error {
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM sqlite_master WHERE type='table' and name='%@';", tableName];
    NSArray<NSDictionary *> *results = [self query:sql success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    BOOL isExist = NO;
    if(results.count) {
        isExist = YES;
    }
    
    if(isExist) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"%@表存在", tableName);
        }
    } else {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"%@表不存在", tableName);
        }
    }
    
    return isExist;
}

- (BOOL)checkTableStructure:(AKDatabaseTable *)table error:(NSError **)error {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@');", table.name];
    NSArray<NSDictionary *> *results = [self query:sql success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    BOOL sameStructure = YES;
    if(results.count != table.columns.count) {
        sameStructure = NO;
    } else {
        for(NSDictionary *columeInfo in results) {
            BOOL isPrimaryKey = [columeInfo[AKDatabaseTableStructureColumnPrimaryKey] boolValue];
            BOOL isNotNull = [columeInfo[AKDatabaseTableStructureColumnNotNullKey] boolValue];
            
            NSString *defaultValue = nil;
            id columnDefaultValue = columeInfo[AKDatabaseTableStructureColumnDefaultValueKey];
            if(![columnDefaultValue isKindOfClass:[NSNull class]]) {
                defaultValue = [NSString stringWithFormat:@"%@", columnDefaultValue];
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name==%@", columeInfo[AKDatabaseTableStructureColumnNameKey]];
            NSArray<AKDatabaseTableColumn *> *columns = [table.columns filteredArrayUsingPredicate:predicate];
            
            if(columns.count != 1) {
                sameStructure = NO;
                break;
            }
            
            AKDatabaseTableColumn *column = columns.lastObject;
            NSString *type = [self convertColumnTypeToSQL:column.type];
            if([columeInfo[AKDatabaseTableStructureColumnTypeKey] isEqualToString:type]
               && isPrimaryKey == column.isPrimaryKey
               && isNotNull == column.isNotNull) {
                if(defaultValue) {
                    if([defaultValue isEqualToString:column.defaultValue]) {
                        continue;
                    }
                } else {
                    if(!column.defaultValue) {
                        continue;
                    }
                }
            }
            
            sameStructure = NO;
            break;
        }
    }
    
    if(sameStructure) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"%@表结构相同", table.name);
        }
    } else {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"%@表结构变更", table.name);
        }
    }
    
    return sameStructure;
}

- (BOOL)createTable:(AKDatabaseTable *)table error:(NSError **)error {
    NSMutableString *sqlM = [NSMutableString string];
    [sqlM appendFormat:@"CREATE TABLE %@", table.name];
    
    NSMutableArray<NSString *> *columnSQLsM = [NSMutableArray array];
    for(AKDatabaseTableColumn *column in table.columns) {
        if(![column.name isKindOfClass:[NSString class]]
           || !column.name.length) {
            continue;
        }
        
        if(column.type == AKDatabaseTableColumnTypeNULL) {
            continue;
        }
        
        NSMutableString *columnSqlM = [NSMutableString string];
        [columnSqlM appendString:column.name];
        
        [columnSqlM appendFormat:@" %@", [self convertColumnTypeToSQL:column.type]];
        
        if(column.isPrimaryKey) {
            [columnSqlM appendString:@" PRIMARY KEY"];
        }
        
        if(column.isAutoincrement) {
            [columnSqlM appendString:@" AUTOINCREMENT"];
        }
        
        if(column.defaultValue) {
            [columnSqlM appendFormat:@" %@", column.defaultValue];
        }
        
        [columnSQLsM addObject:[columnSqlM copy]];
    }
    
    [sqlM appendFormat:@" (%@)", [[columnSQLsM copy] componentsJoinedByString:@", "]];
    
    if(AKDatabase.isDebug) {
        AKDatabaseManagerLog(@"创建表SQL\n%@", [sqlM copy]);
    }
    
    BOOL result = [self update:[sqlM copy] success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    if(!result) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"创建表失败\n%@", *error);
        }
    }
    
    return result;
}

- (NSString *)convertColumnTypeToSQL:(AKDatabaseTableColumnType)type {
    NSString *sqlType = nil;
    switch (type) {
        case AKDatabaseTableColumnTypeInteger: { //INTEGER
            sqlType = @"INTEGER";
            break;
        }
            
        case AKDatabaseTableColumnTypeReal: { //REAL
            sqlType = @"REAL";
            break;
        }
            
        case AKDatabaseTableColumnTypeText: { //TEXT
            sqlType = @"TEXT";
            break;
        }
            
        case AKDatabaseTableColumnTypeBlob: {
            sqlType = @"BLOB";
            break;
        }
            
        default:
            break;
    }
    return sqlType;
}

//更改表名
- (BOOL)alterTable:(NSString *)tableName newTableName:(NSString *)newTableName error:(NSError **)error {
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@", tableName, newTableName];
    BOOL result = [self update:sql success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    if(!result) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"更改表名 %@->%@ 失败\n%@", tableName, newTableName, *error);
        }
    }
    
    return result;
}

static NSString *AKDatabaseTableStructureNameKey = @"name";
static NSString *AKDatabaseTableStructureTypeKey = @"type";

- (BOOL)migrateTable:(NSString *)tableName toTable:(NSString *)newTableName error:(NSError **)error {
    NSString *originStructureSQL = [NSString stringWithFormat:@"PRAGMA TABLE_INFO ('%@')", tableName];
    NSArray<NSDictionary *> *originStructures = [self query:originStructureSQL success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    if(!originStructures.count) {
        return NO;
    }
    
    NSString *newStructureSQL = [NSString stringWithFormat:@"PRAGMA TABLE_INFO ('%@')", newTableName];
    NSArray<NSDictionary *> *newStructures = [self query:newStructureSQL success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    if(!newStructures.count) {
        return NO;
    }
    
    NSMutableArray<NSString *> *columnNamesM = [NSMutableArray array];
    for(NSDictionary *newStructure in newStructures) {
        for(NSDictionary *originStructure in originStructures) {
            if(![newStructure[AKDatabaseTableStructureNameKey] isEqualToString:originStructure[AKDatabaseTableStructureNameKey]]) {
                continue;
            }
            
            if(![newStructure[AKDatabaseTableStructureTypeKey] isEqualToString:originStructure[AKDatabaseTableStructureTypeKey]]) {
                continue;
            }
            
            [columnNamesM addObject:newStructure[AKDatabaseTableStructureNameKey]];
        }
    }
    
    NSString *selectSQL = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
    NSArray<NSDictionary *> *results = [self query:selectSQL success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    if(!results.count) {
        return NO;
    }
    
    NSMutableString *insertSQLM = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", newTableName];
    [insertSQLM appendString:[columnNamesM componentsJoinedByString:@", "]];
    [insertSQLM appendString:@") VALUES ('"];
    
    BOOL result = [self inTransaction:^(AKDatabase * _Nonnull db, BOOL * _Nonnull shouldRollback) {
        for(NSDictionary *result in results) {
            NSMutableString *sqlM = [insertSQLM mutableCopy];
            
            NSMutableArray<id> *valuesM = [NSMutableArray array];
            for(NSString *columnName in columnNamesM) {
                [valuesM addObject:result[columnName]];
            }
            
            [sqlM appendString:[valuesM componentsJoinedByString:@"', '"]];
            [sqlM appendString:@"');"];
            
            BOOL result = [db update:[sqlM copy] success:nil failure:^(NSError * _Nonnull _error) {
                if(error) {
                    *error = _error;
                }
            }];
            
            if(!result) {
                *shouldRollback = YES;
                return;
            }
        }
    } deferred:NO success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    return result;
}

- (BOOL)deleteTable:(NSString *)name error:(NSError **)error {
    NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@", name];
    BOOL result = [self update:sql success:nil failure:^(NSError * _Nonnull _error) {
        if(error) {
            *error = _error;
        }
    }];
    
    if(!result) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"删除过期表 %@ 失败\n%@", name, *error);
        }
    }
    
    return result;
}

- (BOOL)emptyTable:(NSString *)name forceReset:(BOOL)forceReset error:(NSError **)error {
    NSString *sql = nil;
    if(forceReset) {
        sql = [NSString stringWithFormat:@"TRUNCATE TABLE %@", name];
    } else {
        sql = [NSString stringWithFormat:@"DELETE FROM %@", name];
    }
    
    BOOL result = [self update:sql success:nil failure:^(NSError * _Nonnull _error) {
        *error = _error;
    }];
    
    if(!result) {
        if(AKDatabase.isDebug) {
            AKDatabaseManagerLog(@"清理表 %@ 失败\n%@", name, *error);
        }
    }
    
    return result;
}

@end
