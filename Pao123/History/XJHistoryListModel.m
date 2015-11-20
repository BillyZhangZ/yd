//
//  XJHistoryListModel.m
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJHistoryListModel.h"
@implementation XJHistoryListModel

//whenever call it, causes category roll to next
-(void)updateCategory
{
    //Update category
    if(_category == HISTORY_CATEGORY_ALL)  _category = HISTORY_CATEGORY_WEEK;
    else _category++;
}
@end
