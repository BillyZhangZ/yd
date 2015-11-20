//
//  XJHistoryViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJHistoryViewController.h"
#import "XJDetailedHistoryVC.h"
#import "XJHistoryCell.h"
#import "XJHistoryListModel.h"
#import "config.h"
@interface XJHistoryViewController()<UIAlertViewDelegate,UIGestureRecognizerDelegate>
@end
@implementation XJHistoryViewController
{
    bool _isHistoryCellRegistered;
    //used to interact with workouts model
    __weak XJWorkoutManager *_workoutManager;
    XJHistoryListModel *_historyListModel;
 }

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    DEBUG_ENTER;
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationBar.shadowImage = [[UIImage alloc]init];
    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
    
    //prepare pull-refresh table view
    self.pullTableView.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
    self.pullTableView.pullBackgroundColor = [UIColor yellowColor];
    self.pullTableView.pullTextColor = [UIColor blackColor];
    
    //init data model, each time loaded, model will set to default, maybe do this in veiwWillAppear
    _historyListModel = [[XJHistoryListModel alloc]init];

    //set default category, each time user comes back to this view
    _historyListModel.category = HISTORY_CATEGORY_WEEK;
    _historyListModel.numOfRows = [[NSMutableArray alloc]init];
    _historyListModel.totalDistanceOfSection = [[NSMutableArray alloc]init];
    _historyListModel.sectionValue = [[NSMutableArray alloc]init];
    _historyListModel.isSectionHide = [[NSMutableArray alloc]init];
     DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning
{
    DEBUG_ENTER;
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    DEBUG_LEAVE;
}

- (void)dealloc {
    //deinit static variable
    _isHistoryCellRegistered = false;
    self.pullTableView = nil;

}

- (void)viewWillAppear:(BOOL)animated
{
    DEBUG_ENTER;
    [super viewWillAppear:animated];
    NSLog(@"%ld %ld", (long)self.timeBar.frame.size.width, (long)self.allButton.frame.size.width);

    //get history workouts
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    _workoutManager = app.accountManager.currentAccount.workoutManager;
    _historyListModel.LocalWorkouts = _workoutManager.historyWorkouts;
    [self update_historyListModel];
    [self.pullTableView reloadData];

    //view related
    _isHistoryCellRegistered = false;

    DEBUG_LEAVE;
}

#pragma mark - disable landscape
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DEBUG_ENTER;
    XJDetailedHistoryVC *newVC;
    XJWorkout * detailedWorkout;
    NSInteger i = 0, numOfRowsBeforeThisSection = 0;
    for (i = 0; i < indexPath.section; i++) {
        numOfRowsBeforeThisSection += [[_historyListModel.numOfRows objectAtIndex:i] unsignedIntegerValue];
    }
    numOfRowsBeforeThisSection += indexPath.row;
    detailedWorkout = [_historyListModel.LocalWorkouts objectAtIndex:numOfRowsBeforeThisSection];
    
    newVC = [[XJDetailedHistoryVC alloc]init];
    newVC.workout = detailedWorkout;
    [self presentViewController:newVC animated:NO completion:^{}];

    DEBUG_LEAVE;
}

- (void) presentWorkout:(id)workout
{
    // release old presented view
    [self.presentedViewController dismissViewControllerAnimated:NO completion:^(void){}];

    XJDetailedHistoryVC *newVC = [[XJDetailedHistoryVC alloc]init];
    newVC.workout = workout;
    [self presentViewController:newVC animated:NO completion:^{}];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _historyListModel.numOfSections;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger rows;
    [[_historyListModel.isSectionHide objectAtIndex:section] unsignedIntegerValue] == 0? (rows = [[_historyListModel.numOfRows objectAtIndex:section] unsignedIntegerValue]):(rows = 0);
    return rows;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"HistoryCellIdentifier";
    NSInteger i = 0, numOfRowsBeforeThisSection = 0;
    
    if (!_isHistoryCellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"XJHistoryCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"HistoryCellIdentifier"];
        _isHistoryCellRegistered = true;
    }
    
    for (i = 0; i < indexPath.section; i++) {
        numOfRowsBeforeThisSection += [[_historyListModel.numOfRows objectAtIndex:i] unsignedIntegerValue];
    }
    numOfRowsBeforeThisSection += indexPath.row;
    
    XJWorkout *workout;
    workout = [_historyListModel.LocalWorkouts objectAtIndex:numOfRowsBeforeThisSection];

    NSDateFormatter *dateFormater = [[NSDateFormatter alloc]init];
    [dateFormater setDateFormat:@"MM-dd hh:mm:ss"];
    
    XJHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.distance = [NSString stringWithFormat:@"%.2f", workout.summary.length/1000.0f];
    
    NSString *duration = [NSString stringWithFormat:@"%02d:%02d:%02d\n",(unsigned int)workout.summary.duration/3600, (unsigned int)workout.summary.duration%3600/60,(unsigned int)workout.summary.duration%60];
    cell.duration =  [NSString stringWithFormat:@"%@", duration];
    cell.startTime =  [NSString stringWithFormat:@"%@", [dateFormater stringFromDate:workout.summary.startTime]];
#if 0
    CGRect rc = cell.imageIndicator.superview.frame;
    float multiplier = workout.summary.length/1000/10;
    if (multiplier > 1.0) {
        multiplier = 1.0;
    }
    rc.size.width = 20;//cell.imageIndicatorBackground.frame.size.width*multiplier;
    cell.imageIndicator.superview.frame = rc;
    cell.imageIndicator.image = [UIImage imageNamed:@"history_date_active.png"];
    cell.imageIndicatorBackground.image = [UIImage imageNamed:@"history_date_bg.png"];
#endif
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section

{
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc]init];
    NSInteger i = 0, numOfRowsBeforeThisSection = 0;
    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
    UIView *view = [[UIView alloc]initWithFrame:viewFrame];
    view.backgroundColor= [UIColor colorWithRed:31/255.0 green:31/255.0 blue:34/255.0 alpha:1.0];

    CGRect leftLabelFrame = CGRectMake(15, 0, 150, 30);
    CGRect rightLabelFrame = CGRectMake(viewFrame.size.width - 150, 0, 140, 30);
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:leftLabelFrame];
    UILabel *rightLabel = [[UILabel alloc]initWithFrame:rightLabelFrame];
    rightLabel.textAlignment = NSTextAlignmentRight;
    rightLabel.text = [NSString stringWithFormat:@"%lu 项 %.2f公里", (unsigned long)[[_historyListModel.numOfRows objectAtIndex:section] unsignedIntegerValue], [[_historyListModel.totalDistanceOfSection objectAtIndex:section ] unsignedIntegerValue]/1000.0f];
    leftLabel.backgroundColor = [UIColor clearColor];
    rightLabel.backgroundColor = [UIColor clearColor];
    leftLabel.textColor = rightLabel.textColor = [UIColor whiteColor];
    leftLabel.alpha = rightLabel.alpha = 0.40;
    //same size with view
    UIButton *button = [[UIButton alloc]initWithFrame:viewFrame];
    button.tag = section;
   // [button setTitle:@"test" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(tableSectionHeaderClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:button];
    [view addSubview:leftLabel];
    [view addSubview:rightLabel];
    
    for (i = 0; i < section; i++) {
        numOfRowsBeforeThisSection += [[_historyListModel.numOfRows objectAtIndex:i] unsignedIntegerValue];
    }
    
    XJWorkout *workout = [_historyListModel.LocalWorkouts objectAtIndex:numOfRowsBeforeThisSection];
    switch (_historyListModel.category) {
        case HISTORY_CATEGORY_ALL:
            leftLabel.text =  [NSString stringWithFormat:@"所有的"];
            break;
        case HISTORY_CATEGORY_WEEK:
            [dateFormater setDateFormat:@"第w周 YYYY"];
            leftLabel.text = [NSString stringWithFormat:@"%@",[dateFormater stringFromDate: workout.summary.startTime]];
            break;
        case HISTORY_CATEGORY_MONTH:
            [dateFormater setDateFormat:@"YYYY年MM月"];
            leftLabel.text = [NSString stringWithFormat:@"%@",[dateFormater stringFromDate: workout.summary.startTime]];
            break;
        case HISTORY_CATEGORY_YEAR:
            [dateFormater setDateFormat:@"YYYY年"];
            leftLabel.text = [NSString stringWithFormat:@"%@",[dateFormater stringFromDate: workout.summary.startTime]];
            break;
        default:
            break;
    }
    return view;
    //return label;
}

/*
 *delete button on each cell
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    DEBUG_ENTER;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSInteger i = 0, numOfRowsBeforeThisSection = 0;
        for (i = 0; i < indexPath.section; i++) {
            numOfRowsBeforeThisSection += [[_historyListModel.numOfRows objectAtIndex:i] unsignedIntegerValue];
        }
        numOfRowsBeforeThisSection += indexPath.row;
        
        XJLocalWorkout *workout =[_historyListModel.LocalWorkouts objectAtIndex:numOfRowsBeforeThisSection];
        if (![_workoutManager deleteWorkout:workout])
        {
            [self.pullTableView reloadData];
            return;
        }

        [_historyListModel.LocalWorkouts removeObjectAtIndex:numOfRowsBeforeThisSection];
        [self update_historyListModel];
        //Trigger table view to reload
        [self.pullTableView reloadData];
    }
    DEBUG_LEAVE;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
{
    return @" 删除 ";
}

/*
 *Update history data model
 */
-(void)update_historyListModel
{
    DEBUG_ENTER;
    //this category algorithm has a bug when two adjacent workouts is of seem category with different super category
    //like 2014-6 and 2015-6
    NSArray * titleList = @[@"天", @"周", @"月", @"年", @"所有的运动"];
    NSCalendar *tmpCalendar = [NSCalendar currentCalendar];
    if (tmpCalendar == nil) {
        NSLog(@"XJHisotryViewController: tmpCalendar is nil");
    }
    NSInteger unitFlag;
    NSUInteger last = 0, current = 0, numOfRow = 0, totalDistanceOfSection = 0;
    
    //clear some record
    [_historyListModel.numOfRows removeAllObjects];
    [_historyListModel.totalDistanceOfSection removeAllObjects];
    [_historyListModel.sectionValue removeAllObjects];
    _historyListModel.numOfSections = 0;
    
    switch (_historyListModel.category) {
        case HISTORY_CATEGORY_WEEK:
            unitFlag = NSCalendarUnitWeekOfYear;
            break;
        case HISTORY_CATEGORY_MONTH:
            unitFlag = NSCalendarUnitMonth;
            break;
        case HISTORY_CATEGORY_YEAR:
            unitFlag = NSCalendarUnitYear;
        default:
            //used to display all
            unitFlag = NSCalendarUnitEra;
            break;
    }
    
    //should enum from last historyWorkouts
    if (_historyListModel.category == _historyListModel.category) {
         for (XJWorkout *workout in _historyListModel.LocalWorkouts) {
             
             current = [tmpCalendar component:unitFlag fromDate: workout.summary.startTime];
            if (current !=  last) {
                 //update rows of session
                 if (numOfRow != 0) {
                     //a new category, update session number
                     _historyListModel.numOfSections++;
                     if([_historyListModel.isSectionHide count] < _historyListModel.numOfSections)
                     {
                         NSInteger hideValue = 0;
                         NSNumber *hideNumber = [NSNumber numberWithUnsignedInteger:hideValue];
                         [_historyListModel.isSectionHide insertObject:hideNumber atIndex:_historyListModel.numOfSections -1];
                     }
                     NSNumber *value = [NSNumber numberWithUnsignedInteger:numOfRow];
                     [_historyListModel.numOfRows addObject:value];
                     
                     NSNumber *totalLength = [NSNumber numberWithUnsignedInteger:totalDistanceOfSection];
                     [_historyListModel.totalDistanceOfSection addObject:totalLength];
                  }
                last =  current;
                numOfRow = 0;
                totalDistanceOfSection = 0;
             }
             numOfRow++;
             totalDistanceOfSection += workout.summary.length;
        }
        //deal with the last session, since current and last is always the same
        //update rows of session
        if (numOfRow != 0) {
            //a new category, update session number
            _historyListModel.numOfSections++;
            if([_historyListModel.isSectionHide count] < _historyListModel.numOfSections)
            {
                NSInteger hideValue = 0;
                NSNumber *hideNumber = [NSNumber numberWithUnsignedInteger:hideValue];
                [_historyListModel.isSectionHide insertObject:hideNumber atIndex:_historyListModel.numOfSections -1];
            }
            NSNumber *value = [NSNumber numberWithUnsignedInteger:numOfRow];
            [_historyListModel.numOfRows addObject:value];
            
            NSNumber *totalLength = [NSNumber numberWithUnsignedInteger:totalDistanceOfSection];
            [_historyListModel.totalDistanceOfSection addObject:totalLength];
            
         }

    }
    
    _historyListModel.categoryTitle = [titleList objectAtIndex:_historyListModel.category];
    DEBUG_LEAVE;
}

#pragma mark - PullTableViewDelegate
//用户下拉列表触发，向网络同步数据, afterDalay后隐藏下拉动画, 提示用户会使用流量
- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
#pragma mark fix me 切换账户时，需要更新当前帐户下的网络状况
    NSInteger networkStatus = app.networkStatus;

    if (networkStatus == 0) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"貌似无网络" message:@"请稍候再试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        self.pullTableView.pullTableIsRefreshing = NO;
        return;
    }
    
    if (networkStatus == 1) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"当心流量" message:@"当前为移动网络，同步数据会消耗您的流量" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"我是土豪", nil];
        [alert show];
        return;
    }
    //直接下载
    NSString *beforeWhichDate;
    if ([_workoutManager.historyWorkouts count] != 0) {
        beforeWhichDate = stringFromDate([[[[_workoutManager.historyWorkouts lastObject] summary] startTime] dateByAddingTimeInterval:(-1)]);
    }
    else     beforeWhichDate = stringFromDate([[NSDate date] dateByAddingTimeInterval:-1]);
    
    [_workoutManager loadWorkoutListFromServer:beforeWhichDate count:10 delegate:self];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *beforeWhichDate;
        if ([_workoutManager.historyWorkouts count] != 0) {
            beforeWhichDate = stringFromDate([[[[_workoutManager.historyWorkouts lastObject] summary] startTime] dateByAddingTimeInterval:(-1)]);
        }
        else     beforeWhichDate = stringFromDate([[NSDate date] dateByAddingTimeInterval:-1]);
        
        [_workoutManager loadWorkoutListFromServer:beforeWhichDate count:10 delegate:self];
    }
    else         self.pullTableView.pullTableIsRefreshing = NO;
}

#pragma mark - button events
/*
 *Show menu
 */
- (IBAction)menuButtonClicked:(id)sender {
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate showMenu];
}

/*
 * History workouts is displayed with week/month/year/all categories, and each click
 * to this button will cause category to change to next category
 */
-(void)setButtonBackground:(UIButton *)button
{
    [self.weekButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.yearButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.monthButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.allButton setBackgroundImage:nil forState:UIControlStateNormal];
    self.weekButton.alpha = 0.14;
    self.monthButton.alpha = 0.14;
    self.yearButton.alpha = 0.14;
    self.allButton.alpha = 0.14;

    [button setBackgroundImage:[UIImage imageNamed:@"history_bar_active.png"] forState:UIControlStateNormal];
    button.alpha = 0.5;
}
- (IBAction)weekButtonClicked:(id)sender {
    DEBUG_ENTER;
    [self setButtonBackground:(UIButton *)sender];
    _historyListModel.category = HISTORY_CATEGORY_WEEK;
    //re-init section hide flags
    [_historyListModel.isSectionHide removeAllObjects];
    //update data model
    [self update_historyListModel];
    //Trigger table view to reload
    [self.pullTableView reloadData];
    DEBUG_LEAVE;
}
- (IBAction)monthButtonClicked:(id)sender {
    [self setButtonBackground:(UIButton *)sender];

    _historyListModel.category = HISTORY_CATEGORY_MONTH;
    //re-init section hide flags
    [_historyListModel.isSectionHide removeAllObjects];
    //update data model
    [self update_historyListModel];
    //Trigger table view to reload
    [self.pullTableView reloadData];
}

- (IBAction)yearButtonClicked:(id)sender {
    [self setButtonBackground:(UIButton *)sender];

    _historyListModel.category = HISTORY_CATEGORY_YEAR;
    //re-init section hide flags
    [_historyListModel.isSectionHide removeAllObjects];
    //update data model
    [self update_historyListModel];
    //Trigger table view to reload
    [self.pullTableView reloadData];
}

- (IBAction)allButtonClicked:(id)sender {
    [self setButtonBackground:(UIButton *)sender];

    _historyListModel.category = HISTORY_CATEGORY_ALL;
    //re-init section hide flags
    [_historyListModel.isSectionHide removeAllObjects];
    //update data model
    [self update_historyListModel];
    //Trigger table view to reload
    [self.pullTableView reloadData];
}

-(void)tableSectionHeaderClicked:(id)sender
{
    DEBUG_ENTER;
#if 0
    UIButton *button = (UIButton *)sender;
    NSInteger hideValue = !([[_historyListModel.isSectionHide objectAtIndex:button.tag] unsignedIntegerValue]);
    NSLog(@"section button clicked");
    NSNumber *hideNumber = [NSNumber numberWithUnsignedInteger:hideValue];
    [_historyListModel.isSectionHide replaceObjectAtIndex:button.tag withObject:hideNumber];
    [self.pullTableView reloadData];
#endif
    DEBUG_LEAVE;
}

-(void)historyWorkoutUpdated
{
    self.pullTableView.pullLastRefreshDate = [NSDate date];
    self.pullTableView.pullTableIsRefreshing = NO;
    [self update_historyListModel];
    [self.pullTableView reloadData];
}

- (void)handleGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    if(UIGestureRecognizerStateBegan == gesture.state ||
       UIGestureRecognizerStateChanged == gesture.state)
    {
        //根据被触摸手势的view计算得出坐标值
        CGPoint translation = [gesture translationInView:gesture.view];
        NSLog(@"%@", NSStringFromCGPoint(translation));
    }
    else
    {
        AppDelegate *app = [[UIApplication sharedApplication]delegate];
        [app showMenu];
    }
}

@end