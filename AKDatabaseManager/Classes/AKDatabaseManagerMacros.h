//
//  AKDatabaseManagerMacros.h
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#ifndef AKDatabaseManagerMacros_h
#define AKDatabaseManagerMacros_h

#define DEBUG 0

#if DEBUG
    #define AKDatabaseManagerLog(_Format, ...)\
    do {\
        NSString *file = [NSString stringWithUTF8String:__FILE__].lastPathComponent;\
        NSLog((@"\n[%@][%d][%s]\n" _Format), file, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);\
        printf("\n");\
    } while(0)
#else
    #define AKDatabaseManagerLog(_Format, ...)
#endif

#endif /* AKDatabaseManagerMacro_h */
