//
//  XJAccountManager.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/15/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XJAccount.h"


@interface XJAccountManager : NSObject

@property (readonly) XJAccount *currentAccount;
@property (readonly) XJAccount *guestAccount;
// if asGuest is YES, then userName is unused
- (void) logIn:(BOOL)asGuest name:(NSString *)userName complete:(void (^)(BOOL))cb;
- (BOOL) logIn:(NSString *)userName userId:(NSInteger)userId;
- (void) registerWithMobilePhone:(NSString *)phoneNumber complete:(void (^)(bool ok, NSInteger userId))cb;
- (void) loginWithMobilePhone:(NSString *)phoneNumber complete:(void (^)(bool))cb;
- (void) updateAccountInfo:(NSDictionary *)accountInfo;
- (BOOL) storeAccountInfoToDisk;
- (BOOL) loadAccountInfoFromDisk;
- (void) uploadAccountInfo:(void (^)(bool))cb;
@end
