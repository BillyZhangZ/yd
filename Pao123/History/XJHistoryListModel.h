//
//  XJHistoryListModel.h
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#define DISPLAY_HISTORY 0
#define DISPLAY_MOST 1

//categories
typedef enum
{
    HISTORY_CATEGORY_WEEK,
    HISTORY_CATEGORY_MONTH,
    HISTORY_CATEGORY_YEAR,
    HISTORY_CATEGORY_ALL,
}HistoryCategory;

@interface XJHistoryListModel : NSObject

@property HistoryCategory category;
@property NSUInteger numOfSections;
@property NSMutableArray   *numOfRows;
@property NSString         *categoryTitle;
@property NSMutableArray   *sectionValue;
@property NSMutableArray   *isSectionHide;
@property NSMutableArray *totalDistanceOfSection;
@property NSMutableArray  *LocalWorkouts;
-(void)updateCategory;
@end
