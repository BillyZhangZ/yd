//
//  XJLogger.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/21/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XJLogger : NSObject

- (void) log:(NSString *)string;
- (NSString *) loadLogFile;
-(void) restoreLogFile:(NSString *)string;
@end
