//
//  XJRealplayVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/28/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJRealplayVC.h"
#import "XJRemoteWorkout.h"
#import "GdMapReplayView.h"
#import "GdTrackOverlay.h"

#define BUFFERING_TIME 15

@interface Runner : NSObject
@property (nonatomic) NSUInteger userID;
@property (nonatomic) XJRemoteWorkout *workout;
@property (nonatomic) NSDate *lastTime;
@property (nonatomic) BOOL done;
@end

@implementation Runner

@end

@interface XJRealplayVC () <UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate>
{
    UIView *_statusBarView;
    UIView *_toolBarView;

    GdMapReplayView *_gdMapView;

    NSMutableArray *_runners;
    Runner *_selectedRunner;

    // show realtime data
    UIButton *_btnDistance;
    UIButton *_btnHeartRate;
    UIButton *_btnPace;
    UIButton *_btnDuration;

    // show runners
    UIView *_vRunnerListMask; // parent
    UIView *_vRunnerListBackground; // child
    UITableView *_tblRunners; // child
    UIButton *_btnHandle; // child
    BOOL _open;
    
    // actions
    UIButton *_btnClose;
    
    BOOL _quit;

    // media player
    NSTimer *_mediaTimer;
}
@end

@implementation XJRealplayVC

- (void)viewDidLoad {
    DEBUG_ENTER;

    _quit = NO;
    _alwaysFirstRunnerVisible = YES;
    _open = YES;

    [super viewDidLoad];
    // Do any additional setup after loading the view.

    DEBUG_LEAVE;
}

- (void) viewWillAppear:(BOOL)animated
{
    DEBUG_ENTER;
    [super viewWillAppear:animated];

    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    
    _gdMapView = [[GdMapReplayView alloc] initWithFrame:rcScreen];
    _gdMapView.centerLastLocation = NO;
    [self.view addSubview:_gdMapView];
    
    [self performSelector:@selector(onTimer:) withObject:nil afterDelay:0.5];
    
    //----------------------------------------------------------------------------
    // configure status bar
    //----------------------------------------------------------------------------
    _statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rcScreen.size.width, 40)];
    _statusBarView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.7];
    [self.view addSubview:_statusBarView];
    
    // toolbar
    _toolBarView = [[UIView alloc] initWithFrame:CGRectMake(rcScreen.size.width/2 - lo_realplayer_topbar_width/2, STATUSBARHEIGHT-8, lo_realplayer_topbar_width, TITLEBARHEIGHT+8)];
    _toolBarView.backgroundColor = DEFFGCOLORHALF;
    _toolBarView.layer.cornerRadius = 8;
    [self.view addSubview:_toolBarView];
    
#define PLACE_BUTTON(btn, title, rc) \
do {\
btn = [[UIButton alloc] initWithFrame:rc]; \
btn.titleLabel.numberOfLines = 2; \
btn.titleLabel.textAlignment = NSTextAlignmentCenter; \
btn.titleLabel.font = [UIFont systemFontOfSize:13]; \
[btn setTitle:title forState:UIControlStateNormal]; \
[btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; \
[self.view addSubview:btn]; \
} while(0)
    // display data
    CGRect rc;
    NSInteger x = 0;
    NSInteger y = self.view.bounds.origin.y + STATUSBARHEIGHT;
    rc.origin.x = x;
    rc.origin.y = y;
    rc.size.width = self.view.bounds.size.width / 4;
    rc.size.height = TITLEBARHEIGHT;
    PLACE_BUTTON(_btnDistance, @"", rc);
    
    rc.origin.x += rc.size.width;
    PLACE_BUTTON(_btnPace, @"", rc);
    
    rc.origin.x += rc.size.width;
    PLACE_BUTTON(_btnHeartRate, @"", rc);
    
    rc.origin.x += rc.size.width;
    rc.size.width = rcScreen.size.width - rc.origin.x;
    PLACE_BUTTON(_btnDuration, @"", rc);
    
    rc.origin.y = rcScreen.size.height - TITLEBARHEIGHT;
    rc.size.height = TITLEBARHEIGHT;
    rc.size.width = rc.size.width/2 - 2;
    _btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnClose.frame = CGRectMake(0, 0, 32, 32);
    [_btnClose setBackgroundImage:[UIImage imageNamed:@"quit.png"] forState:UIControlStateNormal];
    [_btnClose addTarget:self action:@selector(onCloseClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnClose];
    
    _vRunnerListMask = [[UIView alloc] initWithFrame:rc];
    _vRunnerListMask.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_vRunnerListMask];
    
    rc.origin.x = 0;
    rc.size.width = 16;
    rc.size.height = 24;
    rc.origin.y = _vRunnerListMask.bounds.size.height / 2 - rc.size.height / 2;
    _btnHandle = [[UIButton alloc] initWithFrame:rc];
    _btnHandle.backgroundColor = DEFFGCOLOR;
    if(_open)
        [_btnHandle setTitle:@">" forState:UIControlStateNormal];
    else
        [_btnHandle setTitle:@"<" forState:UIControlStateNormal];
    [_btnHandle addTarget:self action:@selector(onUserListButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [_vRunnerListMask addSubview:_btnHandle];

    rc = _vRunnerListMask.bounds;
    rc.origin.x = 16;
    rc.size.width -= 16;
    _vRunnerListBackground = [[UIView alloc] initWithFrame:rc];
    _vRunnerListBackground.backgroundColor = DEFFGCOLORHALF;
    _vRunnerListBackground.layer.cornerRadius = 8;
    [_vRunnerListMask addSubview:_vRunnerListBackground];

    _tblRunners = [[UITableView alloc] initWithFrame:rc style:UITableViewStylePlain];
    _tblRunners.delegate = self;
    _tblRunners.dataSource = self;
    _tblRunners.rowHeight = 50;
    [_tblRunners setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tblRunners.editing = NO;
    _tblRunners.backgroundColor = [UIColor clearColor];
    rc = _vRunnerListBackground.bounds;
    rc.size.height = _tblRunners.rowHeight * _runners.count;
    rc.origin.y = _vRunnerListBackground.bounds.size.height/2 - rc.size.height/2;
    _tblRunners.frame = rc;
    [_vRunnerListBackground addSubview:_tblRunners];

    [self recalcLayout];

    _mediaTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onMediaTimer:) userInfo:nil repeats:YES];
    DEBUG_LEAVE;
}

- (void) viewWillDisappear:(BOOL)animated
{
    DEBUG_ENTER;

    [XJRealplayVC cancelPreviousPerformRequestsWithTarget:self];

    // do not show any more
    for (UIView *v in [self.view subviews]) {
        [v removeFromSuperview];
    }

    _gdMapView = nil;
    
    [_mediaTimer invalidate];
    _mediaTimer = nil;

    [super viewWillDisappear:animated];
    DEBUG_LEAVE;
}

- (void) dealloc
{
    DEBUG_ENTER;
    NSLog(@"XJRealplayVC: dealloc");
    DEBUG_LEAVE;
}

- (void) onMediaTimer:(NSTimer *)timer
{
    NSDate *to = [NSDate dateWithTimeInterval:-BUFFERING_TIME sinceDate:[NSDate date]];
    // check location
    for(NSUInteger k=0; k<self.userIDs.count; k++) {
        NSAssert(k<_runners.count, @"Bad runner count");
        Runner * runner = [_runners objectAtIndex:k];
        [self runner:runner runTo:to];
    }
}

- (void) runner:(Runner *)runner runTo:(NSDate *)to
{
    if(runner == nil)
        return;

    [_gdMapView updatePaths:to ofWorkout:runner.workout];
    if(self.alwaysFirstRunnerVisible == YES && runner == _selectedRunner) {
        [_gdMapView ensureVisibleLastLocation:runner.workout];
    }
    [self updateData];
}

- (void) setUserIDs:(NSArray *)userIDs
{
    _runners = [[NSMutableArray alloc] init];

    for(NSUInteger i=0; i<userIDs.count; i++) {
        Runner *runner = [[Runner alloc] init];
        NSString *sID = [userIDs objectAtIndex:i];
        runner.userID = [sID intValue];
        runner.workout = [[XJRemoteWorkout alloc] init:((unsigned int)runner.userID)];
        runner.lastTime = [NSDate dateWithTimeIntervalSince1970:0];
        runner.done = NO;
        [_runners addObject:runner];
        if(i == 0)
            _selectedRunner = runner;
    }
    _userIDs = userIDs;
}

- (void) updateData
{
    DEBUG_ENTER;
    if(_selectedRunner == nil)
        return;

    XJWorkout *_workout = _selectedRunner.workout;
    [_btnDistance setTitle:[NSString stringWithFormat:@"%.2f\n距离", (float)_workout.summary.length/1000] forState:UIControlStateNormal];

    NSTimeInterval intval = _workout.summary.duration;
    int hour = (int)(intval/3600);
    int minute = (int)(intval - hour*3600)/60;
    int second = intval - hour*3600 - minute*60;
    [_btnDuration setTitle:[NSString stringWithFormat:@"%02d:%02d:%02d\n时长", hour, minute,second] forState:UIControlStateNormal];

    int rate = [_workout.currentHeartRate intValue];
    NSString *heartRate;
    if(rate == 0)
        heartRate = @"--\n心率";
    else
        heartRate = [NSString stringWithFormat:@"%d\n心率",rate];
    [_btnHeartRate setTitle:heartRate forState:UIControlStateNormal];

//    NSUInteger pace = [_workout calcPace:[NSDate date]];
    NSUInteger pace = 0;
    GdTrackOverlay *overlay = [_gdMapView.gdMapView.overlays firstObject];
    if(overlay != nil && overlay.lastLocation != nil) {
        pace = overlay.lastLocation.speed;
    }
    NSUInteger minutes = pace / 60;
    NSUInteger seconds = pace % 60;
    NSString *sPace = [NSString stringWithFormat:@"%02d:%02d\n配速",(unsigned int)minutes,(unsigned int)seconds];
    [_btnPace setTitle:sPace forState:UIControlStateNormal];
    DEBUG_LEAVE;
}

- (void) onCloseClicked
{
    DEBUG_ENTER;
    // move current workout to history
    [self dismissViewControllerAnimated:NO completion:^(void){}];
    _quit = YES;
    DEBUG_LEAVE;
}

-(void)onTimer:(Runner *)runner
{
    DEBUG_ENTER;

    // request new data
    if(runner == nil) {
        for(NSUInteger k=0; k<self.userIDs.count; k++) {
            NSAssert(k<_runners.count, @"Bad runner count");
            Runner * runner = [_runners objectAtIndex:k];
            if(runner.done == NO)
                [self loadLiveWorkout:(unsigned int)runner.userID];
        }
    }
    else {
        [self loadLiveWorkout:(unsigned int)runner.userID];
    }

    DEBUG_LEAVE;
}

- (Runner *) getRunner:(unsigned int)userID
{
    for(NSUInteger k=0; k<_runners.count; k++) {
        Runner *runner = [_runners objectAtIndex:k];
        if(runner.userID == userID)
            return runner;
    }
    
    return nil;
}

- (void) onReceivedWorkoutData:(NSData *)data forRunner:(Runner *)runner
{
    if(data == nil)
    {
        if(_quit != YES)
            [self performSelector:@selector(onTimer:) withObject:runner afterDelay:3];
        return;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    id val;
    val = [dict objectForKey:@"id"];
    if((NSNull *)val == [NSNull null] || [val intValue] == 0)
    {
        // error or no data
        if(_quit != YES)
            [self performSelector:@selector(onTimer:) withObject:runner afterDelay:3];
        return;
    }
    
    BOOL ret = [runner.workout loadWorkout:dict realTime:YES];
    NSAssert(ret == YES, @"Wrong jason return from live connection");
    
    XJSession *session = runner.workout.sessions.lastObject;
    if(session != nil)
    {
        CLLocation *lastLoc = session.locations.lastObject;
        if(lastLoc != nil)
            runner.lastTime = lastLoc.timestamp;
        else
            runner.lastTime = session.timeStart;
    }
    
    val = [dict objectForKey:@"status"];
    if((NSNull *)val != [NSNull null])
    {
        int status = [val intValue];
        if(status == 4)
        {
            // running
            say(@"运动继续");
        }
        else if(status == 2)
        {
            // finished
            say(@"运动已结束");
            runner.done = YES;
        }
        else if(status == 3)
        {
            // paused
            say(@"运动暂停");
        }
        else if(status == 1)
        {
            // in running state
        }
    }
    
    if(_quit != YES)
        [self performSelector:@selector(onTimer:) withObject:runner afterDelay:5];
}

- (BOOL) loadLiveWorkout:(unsigned int)userID
{
    DEBUG_ENTER;
    if(_quit)
        return NO;
    
    Runner *runner = [self getRunner:userID];
    if(runner == nil)
        return NO;
    myprintf("loadLiveWorkout: send request to server");

    NSMutableString *urlPostWorkout = [[NSMutableString alloc] initWithString:URL_PULL_REALTIME_WORKOUT];
    [urlPostWorkout appendFormat:@"%d",(unsigned int)userID];

    NSURL *url = [NSURL URLWithString:urlPostWorkout];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    NSString *string = [[NSString alloc] initWithFormat:@"starttime=%@",stringFromDate(runner.lastTime)];
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [self onReceivedWorkoutData:data forRunner:runner];
                           }];
    DEBUG_LEAVE;
    return YES;
}

- (void) recalcLayout
{
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rc;
    NSInteger x, y;

    // status bar
    if(rcScreen.size.height > rcScreen.size.width)
    {
        // status bar
        rc = CGRectMake(0, 0, rcScreen.size.width, STATUSBARHEIGHT);
        _statusBarView.frame = rc;
        [self.view addSubview:_statusBarView];
        y = STATUSBARHEIGHT;
    }
    else
    {
        [_statusBarView removeFromSuperview];
        y = 0;
    }

    rc = CGRectMake(rcScreen.size.width/2 - lo_realplayer_topbar_width/2, y-8, lo_realplayer_topbar_width, TITLEBARHEIGHT+8);
    _toolBarView.frame = rc;
    x = rc.origin.x;
    y = rc.origin.y;

    rc.origin.x = x+4;
    rc.origin.y = y + (TITLEBARHEIGHT-32)/2 + 8;
    rc.size.width = 32;
    rc.size.height = 32;
    _btnClose.frame = rc;

    rc.origin.x = x + 48;
    rc.origin.y = y + 2 + 8;
    rc.size.width = (_toolBarView.bounds.size.width - 48) / 4;
    rc.size.height = TITLEBARHEIGHT-4;
    _btnDistance.frame = rc;

    rc.origin.x += rc.size.width;
    _btnPace.frame = rc;

    rc.origin.x += rc.size.width;
    _btnHeartRate.frame = rc;

    rc.origin.x += rc.size.width;
    _btnDuration.frame = rc;
    
    _gdMapView.frame = rcScreen;
    if(_selectedRunner != nil)
        [_gdMapView ensureVisibleLastLocation:_selectedRunner.workout];
    
    rc.size.width = 128;
    rc.origin.x = rcScreen.size.width - rc.size.width + 8;
    rc.origin.y = rc.origin.y + rc.size.height;
    rc.size.height = rc.size.width * 1.5;
    rc.origin.y = (rcScreen.size.height - rc.origin.y - rc.size.height) / 2 + rc.origin.y;
    if(!_open)
        rc.origin.x = rcScreen.size.width - 16; // only a handle is visible
    _vRunnerListMask.frame = rc;
    
    rc.origin.x = 0;
    rc.size.width = 16;
    rc.size.height = 24;
    rc.origin.y = _vRunnerListMask.bounds.size.height / 2 - rc.size.height / 2;
    _btnHandle.frame = rc;


    rc = _vRunnerListMask.bounds;
    rc.origin.x += 16;
    rc.size.width -= 16;
    _vRunnerListBackground.frame = rc;

    rc = _vRunnerListBackground.bounds;
    rc.size.height = _tblRunners.rowHeight * _runners.count;
    if(rc.size.height > _vRunnerListBackground.bounds.size.height - 16)
        rc.size.height = _vRunnerListBackground.bounds.size.height - 16;
    rc.size.width -= 16;
    rc.origin.x = 8;
    rc.origin.y = _vRunnerListMask.bounds.size.height/2 - rc.size.height/2 + 8;
    _tblRunners.frame = rc;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    NSLog(@"rotate: %d %d %d %d", (int)rcScreen.origin.x, (int)rcScreen.origin.y, (int)rcScreen.size.width, (int)rcScreen.size.height);

    [self recalcLayout];

    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_runners count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playRoomCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"playRoomCell"];
        CGRect bounds = tableView.bounds;
        bounds.size.height = tableView.rowHeight;
        CGRect rc;
        
        rc.origin.x = 0;
        rc.origin.y = 0;
        rc.size.width = 2;
        rc.size.height = bounds.size.height;
        UIView *v = [[UIView alloc] initWithFrame:rc];
        v.tag = 1;
        [cell.contentView addSubview:v];

        rc.origin.x = rc.size.width + 2;
        rc.origin.y = 0;
        rc.size.width = 16;
        rc.size.height = 16;
        UIImageView *icon = [[UIImageView alloc] initWithFrame:rc];
        icon.tag = 2;
        [cell.contentView addSubview:icon];

        rc.size.width = 38;
        rc.size.height = 16;
        rc.origin.x = bounds.size.width - rc.size.width;
        rc.origin.y = 0;
        UIButton *btn = [[UIButton alloc] initWithFrame:rc];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:11];
        btn.titleLabel.textAlignment = NSTextAlignmentRight;
        btn.tag = 3;
        [btn setTitle:@"加油" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onClap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:btn];

        rc.origin.x = icon.frame.origin.x;
        rc.origin.y = 14;
        rc.size.width = bounds.size.width - rc.origin.x;
        rc.size.height = bounds.size.height - rc.origin.y;
        UILabel *lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont systemFontOfSize:12];
        lbl.tag = 4;
        [cell.contentView addSubview:lbl];

        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    Runner *runner = [_runners objectAtIndex:indexPath.row];

    UILabel *title = (UILabel *)[cell.contentView viewWithTag:4];
    title.text = [NSString stringWithFormat:@"%d", (int)runner.userID];

    UIImageView *icon = (UIImageView *)[cell.contentView viewWithTag:2];
    icon.image = [UIImage imageNamed:@"portrait.png"];
    
    UIView *v = (UIView *)[cell.contentView viewWithTag:1];
    if(runner == _selectedRunner)
        v.backgroundColor = [UIColor greenColor];
    else
        v.backgroundColor = [UIColor clearColor];

    UIButton *btn = (UIButton *)[cell.contentView viewWithTag:3];
    // how to pass indexPath to onClap:?

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get old index
    int oldRow = [self indexOfSelectedRunner:_selectedRunner];

    // switch runner
    Runner *runner = [_runners objectAtIndex:indexPath.row];
    if(runner == nil)
        return;
    _selectedRunner = runner;

    // update table
    [_tblRunners reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];
    if(oldRow != -1) {
        NSUInteger indexes[2] = {0, oldRow};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
        [_tblRunners reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];
    }

    // update data
    [self updateData];
    
    // update map
    [_gdMapView ensureVisibleLastLocation:runner.workout];
}

- (int) indexOfSelectedRunner:(Runner *)runner
{
    for(NSUInteger i=0; i<_runners.count; i++) {
        Runner *r = [_runners objectAtIndex:i];
        if(r == runner)
            return i;
    }

    return -1;
}

- (void) onClap:(id)sender
{
    
}

- (void) dummy
{
}

- (void) onUserListButtonClicked
{
    _open = !_open;
    CGRect rcScreen = [UIScreen mainScreen].bounds;
    if(_open) {
        CGRect rc = _vRunnerListMask.frame;
        rc.origin.x = rcScreen.size.width - rc.size.width + 8;
        _vRunnerListMask.frame = rc;
        [_btnHandle setTitle:@">" forState:UIControlStateNormal];
    }
    else {
        CGRect rc = _vRunnerListMask.frame;
        rc.origin.x = rcScreen.size.width - 16;
        _vRunnerListMask.frame = rc;
        [_btnHandle setTitle:@"<" forState:UIControlStateNormal];
    }
}
//---------------------------------------------------------------------------------------------
// Only support landscape
//---------------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end
