//
//  XJUserHomeViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/2.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJUserHomeViewController.h"
#import "AppDelegate.h"
#import "basicInfoCel.h"
@interface XJUserHomeViewController ()<UIGestureRecognizerDelegate>
{
    NSInteger _height;
    NSInteger _weight;
    NSInteger _age;
    BOOL cellRegistered;
}

@property (nonatomic, weak) XJAccountManager *accountManager;
@property (nonatomic, weak) XJAccount *myAccount;
@end
@implementation XJUserHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];

    cellRegistered = false;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   
    self.view.userInteractionEnabled = YES;
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    _accountManager = app.accountManager;
    _myAccount = app.accountManager.currentAccount;
    
    _height = _myAccount.height == 0 ?170:_myAccount.height;
    _weight = _myAccount.weight == 0 ?70:_myAccount.weight;
    _age    = _myAccount.age    == 0 ?20:_myAccount.age;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    cellRegistered = false;
    [self hidePickerViewNoAnimate];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    NSLog(@"home vc dealloc");
}


-(void)showPickerView
{
    CGRect rc = [[UIScreen mainScreen]bounds];
    self.view.userInteractionEnabled = YES;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        [self.contentView setFrame:CGRectMake(0, rc.size.height-self.contentView.frame.size.height, rc.size.width, self.contentView.frame.size.height)];
    } completion:^(BOOL isFinished){
        
    }];
}
-(void)hidePickerView
{
    CGRect rc = [[UIScreen mainScreen]bounds];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        self.view.backgroundColor = [UIColor clearColor];
        CGRect rc1 = self.contentView.bounds;
        [self.contentView setFrame:CGRectMake(0, rc.size.height, rc.size.width, rc1.size.height)];
    } completion:^(BOOL isFinished){
        // self.view.userInteractionEnabled = NO;
    }];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        //pickerLabel.minimumFontSize = 8.0;
        //pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setTextColor:[UIColor whiteColor]];
        //[pickerLabel setFont:[UIFont boldSystemFontOfSize:15]];
    }
    // Fill the label text here
    pickerLabel.text=[self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}

-(void)hidePickerViewNoAnimate
{
    CGRect rc = [[UIScreen mainScreen]bounds];
    
    [UIView animateWithDuration:0.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        self.view.backgroundColor = [UIColor clearColor];
        CGRect rc1 = self.contentView.bounds;
        [self.contentView setFrame:CGRectMake(0, rc.size.height, rc.size.width, rc1.size.height)];
    } completion:^(BOOL isFinished){
        // self.view.userInteractionEnabled = NO;
    }];
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
    [[tableView cellForRowAtIndexPath:indexPath] setBackgroundColor: [UIColor clearColor]];
    switch (indexPath.section) {
        case 0:
            self.commonUnit.text = @"厘米";
            [_picker selectRow:_height inComponent:0 animated:NO];
            break;
        case 1:
            self.commonUnit.text = @"公斤";
            [_picker selectRow:_weight inComponent:0 animated:NO];
            break;
        case 2:
            self.commonUnit.text = @"岁";
            [_picker selectRow:_age inComponent:0 animated:NO];
            break;
        default:
            break;
    }
    [self showPickerView];

}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
      return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!cellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"basicInfoCel" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"basicInfoCellIndentifier"];
        cellRegistered = true;
    }
    
    basicInfoCel  *cell = [tableView dequeueReusableCellWithIdentifier:@"basicInfoCellIndentifier"];
    if(cell == nil)
        cell = [[basicInfoCel alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"basicInfoCellIndentifier"];

    switch (indexPath.section) {
        case 0:
            cell.name.text = @"身高";
            cell.value.text = [NSString stringWithFormat:@"%ld", (long)_height];
            cell.unit.text = @"厘米";
            break;
        case 1:
            cell.name.text = @"体重";
            cell.value.text = [NSString stringWithFormat:@"%ld", (long)_weight];
            cell.unit.text = @"公斤";
            break;
        case 2:
            cell.name.text = @"年龄";
            cell.value.text = [NSString stringWithFormat:@"%ld", (long)_age];
            cell.unit.text = @"岁";
            break;
               default:
            break;
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle  = UITableViewCellAccessoryNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section

{
    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
    UIView *view = [[UIView alloc]initWithFrame:viewFrame];
    view.backgroundColor= [UIColor colorWithRed:31/255.0 green:31/255.0 blue:34/255.0 alpha:0.4];
    return view;
    //return label;
}


- (IBAction)backButtonClicked:(id)sender {
    //保存
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app showMenu];
}

- (IBAction)logoutButtonClicked:(id)sender {
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    XJAccountManager *accountManager = app.accountManager;
    [accountManager logIn:true name:@"游客" complete:nil];
    [app jumpToMainVC];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return 300;
}
-(NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [[NSString alloc] initWithFormat:@"%ld",(long)row];

}
- (IBAction)cancleButtonClicked:(id)sender {
    [self hidePickerView];
}
- (IBAction)confirmButtonClicked:(id)sender {
    if ([self.commonUnit.text isEqualToString:@"厘米"]) {
        _height = [_picker selectedRowInComponent:0];
    } else if ([self.commonUnit.text isEqualToString:@"公斤"]) {
        _weight = [_picker selectedRowInComponent:0];
    } else if ([self.commonUnit.text isEqualToString:@"岁"]) {
        _age = [_picker selectedRowInComponent:0];
    }
    [self hidePickerView];
    [self.tableView reloadData];
    _myAccount.height = _height;
    _myAccount.weight = _weight;
    _myAccount.age = _age;
    [_accountManager storeAccountInfoToDisk];
    [_accountManager uploadAccountInfo:nil];
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
