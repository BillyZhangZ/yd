//
//  XJRunGroup.h
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#define RELATIONSHIP_OWN 1
#define RELATIONSHIP_JOIN 2
#define RELATIONSHIP_APPLY 3
#pragma  fix me here need group description
@interface XJRunGroup : NSObject
@property NSInteger groupId;
@property NSString *groupName;
@property NSString *signature;
@property NSInteger relationship;
@property NSInteger memberCount;
@property NSInteger activeMemberCount;
@property NSInteger applyMemberCount;
@property NSMutableArray *allMembers;
@property NSMutableArray *activeMembers;
-(instancetype)init;
-(void)getActiveGroupMembers:(void (^)(bool))cb;
-(void)getGroupInfo:(void (^)(bool))cb;
@end
