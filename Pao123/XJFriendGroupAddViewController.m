//
//  XJFriendGroupAddViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriendGroupAddViewController.h"
#import "XJFriendGroupSearchViewController.h"
#import "XJFriendGroupCreateViewController.h"
@interface XJFriendGroupAddViewController ()<UIGestureRecognizerDelegate>

@end

@implementation XJFriendGroupAddViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
    //self.navigationBar.shadowImage = [[UIImage alloc]init];

    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)searchButtonClicked:(id)sender {
    XJFriendGroupSearchViewController *vc = [[XJFriendGroupSearchViewController alloc]init];
    [self presentViewController:vc animated:NO completion:nil];
}

- (IBAction)createButtonClicked:(id)sender {
    XJFriendGroupCreateViewController *vc = [[XJFriendGroupCreateViewController alloc]init];
    [self presentViewController:vc animated:NO completion:nil];
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
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
@end
