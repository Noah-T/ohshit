//
//  SettingsViewController.m
//  HueQuickStartApp-iOS
//
//  Created by Noah Teshu on 12/15/14.
//  Copyright (c) 2014 Philips. All rights reserved.
//

#import "SettingsViewController.h"
#import "PHControlLightsViewController.h"

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    CGRect buttonFrame = CGRectMake(self.view.frame.size.width /2 -100, 100, 200, 44);
    CGRect dismissFrame = CGRectMake(self.view.frame.size.width /2 - 100, 300, 200, 44);
    
    UIButton *dismiss = [[UIButton alloc]initWithFrame:dismissFrame];
    [dismiss setTitle:@"Dismiss" forState:UIControlStateNormal];
    [dismiss setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [dismiss addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismiss];
    
    self.pairTheMyo = [[UIButton alloc]initWithFrame:buttonFrame];
    [self.pairTheMyo setTitle:@"Pair Myo" forState:UIControlStateNormal];
    [self.pairTheMyo setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.pairTheMyo addTarget:self action:@selector(pairMayo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pairTheMyo];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    

}

- (void)pairMayo
{
    self.settings = [[TLMSettingsViewController alloc] init];
    
    [self.navigationController presentViewController:self.settings animated:YES completion:nil];

}

- (void)dismissView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
