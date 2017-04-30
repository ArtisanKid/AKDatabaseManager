//
//  AKDatabaseManagerMacro.h
//  Pods
//
//  Created by 李翔宇 on 16/9/14.
//
//

#ifndef AKDatabaseManagerMacro_h
#define AKDatabaseManagerMacro_h

#if DEBUG
    #define AKDatabaseManagerLog(_Format, ...) NSLog((@"\n[File:%s]\n[Line:%d]\n[Function:%s]\n" _Format), __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);printf("\n");
#else
    #define AKDatabaseManagerLog(_Format, ...)
#endif

#endif /* AKDatabaseManagerMacro_h */
