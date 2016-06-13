//
//  XWListDetailVC.m
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import "XWListDetailVC.h"
#import "XWCenterPlayer.h"
#import "XWSongModel.h"
@interface XWListDetailVC ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray * _dataSource;
}
@end

@implementation XWListDetailVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"WP.jpg"]];
    
    _dataSource=[NSMutableArray array];
    UIView * footer=[[UIView alloc]init];
    _tableView.tableFooterView=footer;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"detailCell"];
    _tableView.backgroundColor=[UIColor clearColor];
    NSLog(@"TYPE:%d--%@",_type, _urlString);
    
    AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
    //接收到的数据为NSData
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:_urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject){
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        
        if (_type==0) {
            UIView * header=[[UIView alloc]initWithFrame:CGRectMake(0, 0, KWIDTH, 80.0)];
            UIImageView * album_icon=[[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 60, 60)];
            [header addSubview:album_icon];
            UIImageView * creator_icon=[[UIImageView alloc]initWithFrame:CGRectMake(45, 40, 35, 35)];
            [header addSubview:creator_icon];
            UILabel * label=[[UILabel alloc]initWithFrame:CGRectMake(80.0, 10, KWIDTH-100.0, 30.0)];
            label.textColor=[UIColor whiteColor];
            [header addSubview:label];
            label.text=jsonDict[@"albuminfo"][@"album_name"];
            UILabel * creatorLab=[[UILabel alloc]initWithFrame:CGRectMake(100.0, 45.0, 100.0, 25.0)];
            creatorLab.text=jsonDict[@"albuminfo"][@"creator"];
            [header addSubview:creatorLab];
            header.backgroundColor=[UIColor clearColor];
            _tableView.tableHeaderView=header;
            [album_icon sd_setImageWithURL:[NSURL URLWithString:jsonDict[@"albuminfo"][@"album_icon"]] placeholderImage:[UIImage imageNamed:@"music.png"]];
            [creator_icon sd_setImageWithURL:[NSURL URLWithString:jsonDict[@"albuminfo"][@"creator_icon"]] placeholderImage:[UIImage imageNamed:@"STico.png"]];
        }
        _tableView.backgroundColor=[UIColor clearColor];
        NSArray *jsonArray = jsonDict[@"data"];
        [_dataSource removeAllObjects];
        
        for (NSDictionary * dic in jsonArray)
        {
            XWSongModel * song=[[XWSongModel alloc]init];
            song.ID=dic[@"songid"];
            song.Singer=dic[@"singername"];
            song.Name=dic[@"songname"];
            if (dic[@"click"]) {
                song.Click=dic[@"click"];
            }
            [_dataSource addObject:song];
        }
//        [XWPlayerCenter sharePlayer].currentPlay.playList=[NSMutableArray arrayWithArray:_dataSource];
//        [XWPlayerCenter sharePlayer].currentPlay.isOline=YES;
//        [XWPlayerCenter sharePlayer].currentPlay.index=0;
        
        [_tableView reloadData];
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    // Do any additional setup after loading the view from its nib.
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailCell" forIndexPath:indexPath];
    XWSongModel * song=_dataSource[indexPath.row];
    cell.textLabel.text=song.Name;
    cell.textLabel.textColor=[UIColor orangeColor];
    cell.textLabel.font=[UIFont systemFontOfSize:15.0];
    cell.textLabel.numberOfLines=0;
    cell.imageView.image=[UIImage imageNamed:@"music"];
    cell.imageView.clipsToBounds=YES;
    cell.imageView.layer.cornerRadius=5.0;
    // Configure the cell...
    cell.backgroundColor=[UIColor clearColor];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XWSongModel * song=_dataSource[indexPath.row];
    [[XWCenterPlayer ShareCenter] RequestToPlaySong:song];
    [self presentViewController:[XWCenterPlayer ShareCenter] animated:YES completion:^{}];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
