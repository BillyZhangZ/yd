//
//  XJFriends.h
//  Pao123
//
//  Created by 张志阳 on 15/6/29.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define STATE_ALREADY_FRIEND 0
#define STATE_WAIT_FOR_APPROVE 1
@interface XJFriends : NSObject
@property NSUInteger   myId;
@property NSString    *name;
@property NSString    *nickName;
@property UIImage     *portrait;
@property NSInteger   pendingState;
@property NSString    *personalSignature;
@property NSInteger   *totalDistance;
@property NSInteger   *totalDuration;
@property NSInteger   *totalWorkoutCount;
@property NSMutableArray  *myFriend;
-(instancetype)initWithId:(NSInteger)myId name:(NSString *)name nickName:(NSString *) nickName;
@end
