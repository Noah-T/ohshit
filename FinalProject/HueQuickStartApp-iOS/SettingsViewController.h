//
//  SettingsViewController.h
//  HueQuickStartApp-iOS
//
//  Created by Noah Teshu on 12/15/14.
//  Copyright (c) 2014 Philips. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MyoKit/MyoKit.h>


@interface SettingsViewController : UIViewController

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) TLMSettingsViewController *settings;
@property (strong, nonatomic) UIButton *pairTheMyo;

@end
