//
//  NSDictionaryNullReplacement.h
//  Pao123
//
//  Created by 张志阳 on 15/7/11.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (NullReplacement)

- (NSDictionary *)dictionaryByReplacingNullsWithBlanks;
- (NSDictionary *)dictionaryByReplacingNullsWithZero;
@end
