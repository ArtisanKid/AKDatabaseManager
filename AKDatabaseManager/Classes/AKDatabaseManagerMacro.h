//
//  AKDatabaseManagerMacro.h
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#ifndef AKDatabaseManagerMacro_h
#define AKDatabaseManagerMacro_h

static BOOL AKDMLogState = YES;

#define AKDMLogFormat(INFO, ...) [NSString stringWithFormat:(@"\n[Date:%s]\n[Time:%s]\n[File:%s]\n[Line:%d]\n[Function:%s]\n" INFO @"\n\n"), __DATE__, __TIME__, __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__] 

#if DEBUG
#define AKDMLog(INFO, ...) !AKDMLogState ? : NSLog((@"\n[Date:%s]\n[Time:%s]\n[File:%s]\n[Line:%d]\n[Function:%s]\n" INFO @"\n\n"), __DATE__, __TIME__, __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);
#else
#define AKDMLog(INFO, ...)
#endif

#endif /* AKDatabaseManagerMacro_h */
