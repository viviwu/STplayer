//
//  XWAppDelegate.m
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import "XWAppDelegate.h"
#import "XWCenterPlayer.h"
#import "XWPlayListVC.h"
#import "XWSavedListVC.h"
#import "XWListDetailVC.h"

@interface XWAppDelegate()
{
    UITabBarController * _tabBarCtr;
    //    UIToolbar * _customTabBar;
}
@end

@implementation XWAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    _list=[[XWPlayListVC   alloc]init];
    UINavigationController * listNav=[[UINavigationController alloc]initWithRootViewController:_list];
    
    _saved=[[XWSavedListVC alloc]init];
    UINavigationController * savedNav=[[UINavigationController alloc]initWithRootViewController:_saved];
    
    [listNav.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav.png"] forBarMetrics:UIBarMetricsDefault];
    [savedNav.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav.png"] forBarMetrics:UIBarMetricsDefault];
    
    _tabBarCtr=[[UITabBarController alloc]init];
    [_tabBarCtr setViewControllers:@[listNav, savedNav] animated:YES];
    _tabBarCtr.selectedIndex=0;
    
    [self setCustomTabBarCtr];
    
    self.window.rootViewController=_tabBarCtr;
    
    
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

-(void)setCustomTabBarCtr
{
    _tabBarCtr.tabBar.hidden = YES;//隐藏当前的tabbar栏
    //创建自己的 tabbar
    //设置toolbar内容
    self.customTabBar=[[UIView alloc]initWithFrame:CGRectMake(0, KHEIGHT-49.0, KWIDTH, 49.0)];
    //    self.customTabBar.backgroundColor=[UIColor clearColor];
    self.customTabBar.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"toolbar.png"]];
    NSArray * imgArr=@[@"burn.png", @"arrow_left.png", @"play.png", @"arrow_right.png", @"favorites.png"];
    for (int i=0; i<5; i++)
    {
        UIButton * btn=[[UIButton alloc]initWithFrame:CGRectMake(10+i*KWIDTH/5-5, 3, KWIDTH/6, 45.0)];
        [btn setBackgroundImage:[UIImage imageNamed:imgArr[i]] forState:UIControlStateNormal];
        btn.selected=NO;
        if (i==2) {
            [btn setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateSelected];
            _playerSwitchHander=^(BOOL isPlaying){
                if (isPlaying) {
                    btn.selected=YES;
                }else{
                    btn.selected=NO;
                }
            };
        }
        btn.tag=i;
        [self.customTabBar addSubview:btn];
        [btn addTarget:self action:@selector(indexAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    self.customTabBar.hidden=NO;
    
    [_tabBarCtr.view addSubview:_customTabBar];
}

-(void)indexAction:(UIButton*)btn
{
    switch (btn.tag) {
        case 0:
            _tabBarCtr.selectedIndex=0;
            break;
        case 1:
            [[XWCenterPlayer ShareCenter] playBack:[XWCenterPlayer ShareCenter].playBackBTN];
            break;
        case 2:
            [[XWCenterPlayer ShareCenter] playOrPause:[XWCenterPlayer ShareCenter].playOrPauseBTN];
            //btn.selected=!btn.selected;
            break;
        case 3:
            [[XWCenterPlayer ShareCenter] playForward:[XWCenterPlayer ShareCenter].playForwardBTN];
            break;
        case 4:
            _tabBarCtr.selectedIndex=1;
            break;
        default:
            break;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // 后台播放三步骤之一:让应用在后台运行
    [application beginBackgroundTaskWithExpirationHandler:nil];//没有卵用
    
    
    //后台或锁屏下接受播放控制事件（播放、暂停、下一曲等操作）
    [application beginReceivingRemoteControlEvents];
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"STplayer" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"STplayer.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
