//
//  XWSavedListVC.m
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import "XWSavedListVC.h"
#import "XWSongModel.h"
#import "XWCenterPlayer.h"

@interface XWSavedListVC ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray * _localSongs;
    UIBarButtonItem * _btnItemR1;
    UIBarButtonItem * _btnItemR2;
}
@end

@implementation XWSavedListVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _localSongs=[NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"本地收藏";
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"su.jpg"]];
    
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"_LOCAL_"];
    self.tableView.backgroundColor=[UIColor clearColor];
    
    _btnItemR1=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(itemRightButtonClick:)];
    self.navigationItem.rightBarButtonItem=_btnItemR1;
    
    UIButton * lBTN=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 40, 35)];
    [lBTN setImage:[UIImage imageNamed:@"itunes.png"] forState:UIControlStateNormal];
    [lBTN addTarget:self action:@selector(showPlayer) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * lBBI=[[UIBarButtonItem alloc]initWithCustomView:(UIView*)lBTN];
    self.navigationItem.leftBarButtonItem=lBBI;
    // Do any additional setup after loading the view from its nib.
}

-(void)showPlayer{
    [self presentViewController:[XWCenterPlayer ShareCenter] animated:YES completion:^{
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_localSongs removeAllObjects];
    
    [self searchLocalFilesForSongs];
}
//扫描磁盘上的歌曲文件
-(void)searchLocalFilesForSongs{
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:kDownloadPath]) return;
    NSLog(@"%@", kDownloadPath);
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:kDownloadPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        //NSString* fileAbsolutePath = [documents stringByAppendingPathComponent:fileName];
        NSLog(@"%@",fileName);
        NSRange range = [fileName rangeOfString:@".mp3"];
        if (range.location != NSNotFound) {
            [_localSongs addObject:[NSString stringWithFormat:@"%@",fileName]];
        }
    }
    
    [_tableView reloadData];
    NSLog(@"%@",_localSongs);
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  _localSongs.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell=[tableView dequeueReusableCellWithIdentifier:@"_LOCAL_"];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"_LOCAL_"];
    }
    cell.textLabel.text=[NSString stringWithFormat:@"收藏曲目-------(%ld)", (long)indexPath.row];
    cell.textLabel.textColor=[UIColor greenColor];
    cell.detailTextLabel.text=_localSongs[indexPath.row];
    cell.detailTextLabel.textColor=[UIColor yellowColor];
    cell.detailTextLabel.numberOfLines=0;
    cell.backgroundColor=[UIColor clearColor];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString * filepath=[[NSString stringWithFormat:@"file:///%@/%@", kDownloadPath,_localSongs[indexPath.row]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL * pathURL=[NSURL URLWithString:filepath];
    XWSongModel * song =[[XWSongModel alloc]init];
    song.Name=_localSongs[indexPath.row];
    song.filePath=filepath;
    [XWCenterPlayer ShareCenter].currentSong=song;
    [[XWCenterPlayer ShareCenter].playedQueue addObject:song];
    
    [[XWCenterPlayer ShareCenter] playerPlay:pathURL];
    
    NSLog(@"%@", pathURL);
}


-(void)itemRightButtonClick:(id)sender
{
    if (_btnItemR2==nil) {
        _btnItemR2=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(itemRightButtonClick:)];
    }
    
    //设置可以编辑
    [self.tableView setEditing:!self.tableView.editing];//设置成和当前状态相反的状态
    if (self.tableView.editing)
    {
        self.navigationItem.rightBarButtonItem=_btnItemR2;
    } else  {
        self.navigationItem.rightBarButtonItem=_btnItemR1;
    }
}
//设置编译图标
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //删除
    return UITableViewCellEditingStyleDelete;
}
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //从磁盘删除制定文件
    [self deleteFileWithName:_localSongs[indexPath.row]];
    
    NSInteger row = [indexPath row];
    NSLog(@"%@",_localSongs);
    [_localSongs removeObjectAtIndex:row];
    NSLog(@"%@",_localSongs);
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
}

-(void)deleteFileWithName:(NSString*)name
{
    NSString * filePath=[NSString stringWithFormat:@"%@/%@", kDownloadPath,name];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:kDownloadPath]) return;
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:kDownloadPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if ([name isEqualToString:fileName]) {
            [manager removeItemAtPath:filePath error:nil];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
