//
//  XJAccount.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/23/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJWorkoutManager.h"
#import "XJFriends.h"
#define MALE 1
#define FEMALE 2

@interface XJAccount : NSObject
@property (nonatomic) NSUInteger userID;
@property (nonatomic) NSString *user;
@property (nonatomic) NSString *nickName;
@property (nonatomic) bool      sex;
@property (nonatomic) NSUInteger height;
@property (nonatomic) NSUInteger weight;
@property (nonatomic) NSUInteger age;
@property (nonatomic) NSDate *registerdate;
@property (nonatomic) NSMutableArray *friends;
@property (nonatomic) NSMutableArray *runGroups;

@property (nonatomic) BOOL autoPause;
@property (nonatomic) XJWorkoutManager *workoutManager;

//0:no network 1:WWAN 2:WI-FI
// whether to enable voice helper
@property (nonatomic) BOOL voiceHelper;
// gui layout
@property (nonatomic) char *btnLayout;

// if isGuest is YES, then userName is unused
- (instancetype) init:(BOOL)isGuest name:(NSString *)userName userID:(NSUInteger)userID;

- (void) login:(void (^)(BOOL ok))cb;
- (void) logout; // no need to wait done

// Friend management
- (void) addFriend:(NSInteger)friendId complete:(void(^)(bool))cb;
- (BOOL) rmFriend:(NSInteger)userId;
-(void)getFriendList:(void (^)(BOOL ok))cb;
- (void) getApplyFriendList:(void (^)(BOOL ok))cb;
-(void)getFriendGroupFromServer:(void(^)(bool))cb;
@end
