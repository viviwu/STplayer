//
//  XWPlayListVC.h
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PlayerRotation)(void);
@interface XWPlayListVC : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *segCtr;
- (IBAction)cahngeCategory:(UISegmentedControl *)sender;

@property(nonatomic, strong)PlayerRotation PlayerRotationHander;
@end
