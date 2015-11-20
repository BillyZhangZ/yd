//
//  XJWorkoutListVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/15/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJWorkoutListVC.h"
#import "XJWorkout.h"
#import "XJTraceTrackVC.h"

@interface XJWorkoutListVC () <UITableViewDelegate, UITableViewDataSource>
{
    UITableView *_tblWorkouts;
}

@end

@implementation XJWorkoutListVC

- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.vcTitle = @"该用户的跑步记录";
    self.leftButtonImage = @"menu.png";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(onBtnMenu) forControlEvents:UIControlEventTouchUpInside];
    
    _tblWorkouts = [[UITableView alloc] initWithFrame:self.clientRect];
    _tblWorkouts.delegate = self;
    _tblWorkouts.dataSource = self;
    [self.view addSubview:_tblWorkouts];
    DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DEBUG_LEAVE;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) onBtnMenu
{
    DEBUG_ENTER;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate showMenu];
    DEBUG_LEAVE;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.workouts = app.accountManager.currentAccount.workoutManager.historyWorkouts;

    return self.workouts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendWorkoutTableCell"];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"friendWorkoutTableCell"];

    cell.accessoryType = UITableViewCellAccessoryNone;
    if(indexPath.row < self.workouts.count)
    {
        XJWorkout *wo = [self.workouts objectAtIndex:indexPath.row];
        NSMutableString *subtitle = [[NSMutableString alloc] initWithString:@""];
        NSString *title = stringFromDate(wo.summary.startTime);
        [subtitle appendFormat:@"%d meters %d seconds",(int)wo.summary.length,(int)wo.summary.duration];
        cell.textLabel.text = title;
        cell.detailTextLabel.text = subtitle;
        cell.imageView.image = nil;
    }
    else
    {
        cell.textLabel.text = @"";
        cell.imageView.image = nil;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < self.workouts.count)
    {
        XJWorkout *wo = [self.workouts objectAtIndex:indexPath.row];
        XJTraceTrackVC *vc = [[XJTraceTrackVC alloc] init];
        vc.workout = wo;
        vc.speed = 20.0;
        [self presentViewController:vc animated:NO completion:^{}];
    }
}

@end
