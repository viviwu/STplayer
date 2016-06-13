//
//  XWAppDelegate.h
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XWPlayListVC.h"
#import "XWSavedListVC.h"

typedef void(^palyStateSwitchHandler)(BOOL isPlaying);

@interface XWAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (strong, nonatomic)XWPlayListVC  * list;
@property (strong, nonatomic)XWSavedListVC * saved;

@property(nonatomic, strong)UIView * customTabBar;
@property(nonatomic, strong)palyStateSwitchHandler playerSwitchHander;

@end
