//
//  AKDatabaseConstants.h
//  Pods
//
//  Created by 李翔宇 on 2017/9/13.
//
//

#ifndef AKDatabaseConstants_h
#define AKDatabaseConstants_h

#ifdef __OBJC__
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AKDatabaseErrorCode) {
    AKDatabaseErrorCodeParamLack, //参数缺失
    AKDatabaseErrorCodeParamError, //参数错误
    AKDatabaseErrorCodeParamTypeError, //参数类型错误
    AKDatabaseErrorCodeSQLiteError, //SQLite错误
};

#endif

#endif /* AKDatabaseConstants_h */
