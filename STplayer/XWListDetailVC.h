//
//  XWListDetailVC.h
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XWListDetailVC : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, assign)int type;
@property(nonatomic,copy)NSString * urlString;

@end
