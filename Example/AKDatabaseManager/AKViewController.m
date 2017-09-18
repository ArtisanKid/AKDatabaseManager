//
//  AKViewController.m
//  AKDatabaseManager
//
//  Created by Freud on 09/14/2016.
//  Copyright (c) 2016 Freud. All rights reserved.
//

#import "AKViewController.h"
#import <AKDatabaseManager/AKDatabase.h>

#import <FMDB/FMDB.h>

@interface AKViewController ()

@end

@implementation AKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@", NSHomeDirectory());
    NSString *path = [NSString stringWithFormat:@"%@/Documents/test.db", NSHomeDirectory()];
    AKDatabase *database = [AKDatabase dataWithPath:path];
    database.debug = YES;
    if(![database open:nil]) {
        return;
    }
    
    AKDatabaseTableColumn *column0 = [[AKDatabaseTableColumn alloc] initWithName:@"a" type:AKDatabaseTableColumnTypeInteger];
    column0.autoincrement = YES;
    AKDatabaseTableColumn *column1 = [[AKDatabaseTableColumn alloc] initWithName:@"b" type:AKDatabaseTableColumnTypeReal];
    AKDatabaseTableColumn *column2 = [[AKDatabaseTableColumn alloc] initWithName:@"c" type:AKDatabaseTableColumnTypeText];
    AKDatabaseTableColumn *column3 = [[AKDatabaseTableColumn alloc] initWithName:@"d" type:AKDatabaseTableColumnTypeBlob];
    AKDatabaseTableColumn *column4 = [[AKDatabaseTableColumn alloc] initWithName:@"e" type:AKDatabaseTableColumnTypeBlob];
    AKDatabaseTableColumn *column5 = [[AKDatabaseTableColumn alloc] initWithName:@"f" type:AKDatabaseTableColumnTypeBlob];
    AKDatabaseTableColumn *column6 = [[AKDatabaseTableColumn alloc] initWithName:@"g" type:AKDatabaseTableColumnTypeBlob];
    AKDatabaseTableColumn *column7 = [[AKDatabaseTableColumn alloc] initWithName:@"h" type:AKDatabaseTableColumnTypeBlob];
    AKDatabaseTableColumn *column8 = [[AKDatabaseTableColumn alloc] initWithName:@"i" type:AKDatabaseTableColumnTypeBlob];
    AKDatabaseTable *table = [[AKDatabaseTable alloc] initWithName:@"test" columns:@[column0, column1, column2, column3, column4, column5, column6, column7, column8]];
    
    NSError *error = nil;
    if(![database createTable:table policy:AKDatabaseTableCreateMigrate error:&error]) {
        NSLog(@"%@", error);
        return;
    }
    
    NSLog(@"%@", @(NSDate.date.timeIntervalSince1970));
    
//    [database inTransaction:^(AKDatabase * _Nonnull db, BOOL * _Nonnull shouldRollback) {
//        for(int i = 0; i < 10000; i++) {
//            NSString *str = [NSString stringWithFormat:@"第%@条记录", @(i)];
//
//            NSString *sql1 = [NSString stringWithFormat:@"INSERT INTO test(b, c, d) VALUES ('%@', '%@', '%@');", @(i + .1), str, [str dataUsingEncoding:NSUTF8StringEncoding]];
//            [database update:sql1 success:nil failure:nil];
//        }
//    } deferred:NO success:nil failure:nil];
    
//    for(int i = 0; i < 10000; i++) {
//        NSString *str = [NSString stringWithFormat:@"第%@条记录", @(i)];
//
//        NSString *sql2 = [NSString stringWithFormat:@"SELECT * FROM test WHERE c='%@';", str];
//        [database query:sql2 success:nil failure:nil];
//    }
    
    NSLog(@"%@", @(NSDate.date.timeIntervalSince1970));
    
    FMDatabaseQueue *queue = [[FMDatabaseQueue alloc] initWithPath:path];
    FMDatabase *db = [[FMDatabase alloc] initWithPath:path];
    [db open];
    
    NSLog(@"%@", @(NSDate.date.timeIntervalSince1970));
    
//    for(int i = 0; i < 10000; i++) {
//        NSString *str = [NSString stringWithFormat:@"第%@条记录", @(i)];
//
//        NSString *sql2 = [NSString stringWithFormat:@"SELECT * FROM test WHERE c='%@';", str];
//        FMResultSet *set = [db executeQuery:sql2];
//        NSMutableArray *arrM = [NSMutableArray array];
//        while ([set next]) {
//            [arrM addObject:set.resultDictionary];
//        }
//        [set close];
//    }
    
//    [queue inDatabase:^(FMDatabase *db) {
//        for(int i = 0; i < 10000; i++) {
//            NSString *str = [NSString stringWithFormat:@"第%@条记录", @(i)];
//
//            NSString *sql1 = [NSString stringWithFormat:@"INSERT INTO test(b, c, d) VALUES ('%@', '%@', '%@');", @(i + .1), str, [str dataUsingEncoding:NSUTF8StringEncoding]];
//            [db executeUpdate:sql1];
//        }
//    }];
    
//    for(int i = 0; i < 10000; i++) {
//        NSString *str = [NSString stringWithFormat:@"第%@条记录", @(i)];
//
//        NSString *sql1 = [NSString stringWithFormat:@"INSERT INTO test(b, c, d) VALUES ('%@', '%@', '%@');", @(i + .1), str, [str dataUsingEncoding:NSUTF8StringEncoding]];
//        [db executeUpdate:sql1];
//
//        NSString *sql2 = [NSString stringWithFormat:@"SELECT * FROM test WHERE c='%@';", str];
//        [[db executeQuery:sql2] close];
//    }
    NSLog(@"%@", @(NSDate.date.timeIntervalSince1970));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
