//
//  XWPlayListVC.m
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import "XWPlayListVC.h"
#import "XWSongModel.h"
#import "XWAlbumModel.h"
#import "XWAlbumCell.h"
#import "XWtagCell.h"
#import "XWListDetailVC.h"
#import "GDataXMLNode.h"
#import "XWCenterPlayer.h"

#define viewHeight KHEIGHT-64-29.0-49.0
@interface XWPlayListVC ()<UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
{
    NSArray * _listURLs;
    NSMutableArray * _latestArr;
    NSMutableArray * _hotSTArr;
    NSMutableArray * _albumArr;
    NSMutableArray * _tagsArr;
    
}
@property(nonatomic, strong)UIScrollView * mainScroll;
@property(nonatomic, strong)UITableView * latestTable;
@property(nonatomic, strong)UITableView * SThotTable;
@property(nonatomic, strong)UICollectionView *albumCollection;
@property(nonatomic, strong)UICollectionView * tagsCollection;
@property(nonatomic, strong)UIButton * lBTN;
@end

@implementation XWPlayListVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _listURLs=@[rec_ListURL, hot_ListURL, albumsListURL, tagListURL];
        _latestArr=[NSMutableArray array];
        _hotSTArr =[NSMutableArray array];
        _albumArr =[NSMutableArray array];
        _tagsArr = [NSMutableArray array];
        
    }
    return self;
}

-(void)initMainViews
{
    _mainScroll=[[UIScrollView alloc]initWithFrame:CGRectMake(0, 29.0, KWIDTH, viewHeight)];
    _mainScroll.backgroundColor=[UIColor clearColor];
    [self.view addSubview:_mainScroll];
    _mainScroll.contentSize=CGSizeMake(KWIDTH*4, 0);//滚动范围偏移量
    _mainScroll.delegate=self;
    _mainScroll.pagingEnabled = YES;//设置翻页效果
    _mainScroll.showsHorizontalScrollIndicator = NO;
    
    _latestTable=[[UITableView alloc]initWithFrame:CGRectMake(0, 0, KWIDTH, viewHeight) style:UITableViewStylePlain];
    _latestTable.delegate=self;
    _latestTable.dataSource=self;
    [_mainScroll addSubview:_latestTable];
    
    
    _SThotTable=[[UITableView alloc]initWithFrame:CGRectMake(KWIDTH, 0, KWIDTH, viewHeight) style:UITableViewStylePlain];
    _SThotTable.delegate=self;
    _SThotTable.dataSource=self;
    [_mainScroll addSubview:_SThotTable];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    [flowLayout setItemSize:CGSizeMake(90, 120)];//设置cell的尺寸
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];//设置其布局方向
    //flowLayout.minimumLineSpacing=5;//for lines
    flowLayout.minimumInteritemSpacing=5;//for cells
    flowLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);//辅助设置组边界Top,bottom,left,right
    //其布局很有意思，当你的cell设置大小后，一行多少个cell，由cell的宽度决定
    _albumCollection=[[UICollectionView alloc]initWithFrame:CGRectMake(2*KWIDTH, 0, KWIDTH, viewHeight) collectionViewLayout:flowLayout];
    _albumCollection.backgroundColor=[UIColor whiteColor];
    _albumCollection.dataSource = self;
    _albumCollection.delegate = self;
    [_mainScroll addSubview:_albumCollection];
    
    UICollectionViewFlowLayout *flowLayout2 = [[UICollectionViewFlowLayout alloc]init];
    [flowLayout2 setItemSize:CGSizeMake(55, 25)];//设置cell的尺寸
    [flowLayout2 setScrollDirection:UICollectionViewScrollDirectionVertical];//设置其布局方向
    //flowLayout2.minimumLineSpacing=10;//for lines
    flowLayout2.minimumInteritemSpacing=2;//for cells
    flowLayout2.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);//辅助设置组边界Top,bottom,left,right
    //其布局很有意思，当你的cell设置大小后，一行多少个cell，由cell的宽度决定
    _tagsCollection=[[UICollectionView alloc]initWithFrame:CGRectMake(3*KWIDTH, 0, KWIDTH, viewHeight) collectionViewLayout:flowLayout2];
    _tagsCollection.backgroundColor=[UIColor whiteColor];
    _tagsCollection.dataSource = self;
    _tagsCollection.delegate = self;
    [_mainScroll addSubview:_tagsCollection];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"BG.jpg"]];
    //iOS7以后最好加上这一句，防止UI紊乱
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    _segCtr.selectedSegmentIndex=0;
    
    [self initMainViews];

    [_albumCollection registerNib:[UINib nibWithNibName:@"XWAlbumCell" bundle:nil] forCellWithReuseIdentifier:@"albumCell"];
    [_tagsCollection registerNib:[UINib nibWithNibName:@"XWtagCell" bundle:nil] forCellWithReuseIdentifier:@"tagsCell"];
    
    _latestTable.backgroundColor=[UIColor clearColor];
    _SThotTable.backgroundColor=[UIColor clearColor];
    _albumCollection.backgroundColor=[UIColor clearColor];
    _tagsCollection.backgroundColor=[UIColor clearColor];
    [self requestDataFromUrl:_listURLs[0]];
    
    _lBTN=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 45)];
    [_lBTN setImage:[UIImage imageNamed:@"itunes.png"] forState:UIControlStateNormal];
    [_lBTN addTarget:self action:@selector(showPlayer) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * lBBI=[[UIBarButtonItem alloc]initWithCustomView:(UIView*)_lBTN];
    self.navigationItem.leftBarButtonItem=lBBI;
    
    __weak XWPlayListVC * weakSelf=self;
    _PlayerRotationHander=^{
        weakSelf.lBTN.imageView.transform=CGAffineTransformRotate(weakSelf.lBTN.imageView.transform, 30.0/180.0 * M_PI);
    };
    // Do any additional setup after loading the view from its nib.
}

-(void)showPlayer{
    [self presentViewController:[XWCenterPlayer ShareCenter] animated:YES completion:^{
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)requestDataFromUrl:(NSString *)UrlStr
{
    AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
    //接收到的数据为NSData
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:UrlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
         //NSLog(@"%@", jsonDict);
         NSArray *jsonArray = jsonDict[@"data"];
         if ([jsonDict[@"code"] intValue]==1)
         {
             switch (_segCtr.selectedSegmentIndex) {
                 case 0:
                     [_latestArr removeAllObjects];
                     for (NSDictionary * dic in jsonArray)
                     {
                         XWSongModel  * song=[[XWSongModel alloc]init];
                         song.UserID=dic[@"UserID"];
                         song.UserName=dic[@"UserName"];
                         song.UserIcon=dic[@"UserIcon"];
                         
                         song.ID=dic[@"ID"];
                         song.Name=dic[@"Name"];
                         song.UpUName=dic[@"UpUName"];
                         song.Singer=dic[@"Singer"];
                         song.UpUIcon=dic[@"UpUIcon"];
                         
                         song.Click=dic[@"Click"];
                         song.GradeNum=dic[@"GradeNum"];
                         song.FavNum=dic[@"FavNum"];
                         
                         song.Click=dic[@"RateDT"];
                         song.GradeNum=dic[@"RateUID"];
                         song.FavNum=dic[@"RateUName"];
                         //NSLog(@"%@--%@--%@", dic[@"Name"], dic[@"UpUName"], dic[@"Singer"]);
                         [_latestArr addObject:song];
                     }
                     [_latestTable reloadData];
                     break;
                 case 1:
                     [_hotSTArr removeAllObjects];
                     for (NSDictionary * dic in jsonArray)
                     {
                         XWSongModel  * song=[[XWSongModel alloc]init];
                         song.UserID=dic[@"UserID"];
                         song.UserName=dic[@"UserName"];
                         song.UserIcon=dic[@"UserIcon"];
                         
                         song.ID=dic[@"ID"];
                         song.Name=dic[@"Name"];
                         song.UpUName=dic[@"UpUName"];
                         song.Singer=dic[@"Singer"];
                         song.UpUIcon=dic[@"UpUIcon"];
                         
                         song.Click=dic[@"Click"];
                         song.GradeNum=dic[@"GradeNum"];
                         song.FavNum=dic[@"FavNum"];
                         
                         song.Click=dic[@"RateDT"];
                         song.GradeNum=dic[@"RateUID"];
                         song.FavNum=dic[@"RateUName"];
                         [_hotSTArr addObject:song];
                     }
                     [_SThotTable reloadData];
                     break;
                 case 2:
                     [_albumArr removeAllObjects];
                     for (NSDictionary * dic in jsonArray)
                     {
                         XWAlbumModel * album=[[XWAlbumModel alloc]init];
                         album.album_name=dic[@"album_name"];
                         album.album_id=dic[@"album_id"];
                         album.album_icon=dic[@"album_icon"];
                         [_albumArr addObject:album];
                     }
                     [_albumCollection reloadData];
                     break;
                 case 3:
                     [_tagsArr removeAllObjects];
                     [_tagsArr addObjectsFromArray:jsonArray];
                     [_tagsCollection    reloadData];
                     break;
                     
                 default:
                     break;
             }
         }
     }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"error==%@", error);
     }];
}

- (IBAction)cahngeCategory:(UISegmentedControl *)sender
{
    //滚动到指定区域
    _mainScroll.contentOffset=CGPointMake(KWIDTH *sender.selectedSegmentIndex, 0);
    switch (sender.selectedSegmentIndex) {
        case 0:
            if (_latestArr.count>1) {
                return;
            }
            break;
        case 1:
            if (_hotSTArr.count>1) {
                return;
            }
            break;
        case 2:
            if (_albumArr.count>1) {
                return;
            }
            break;
        case 3:
            if (_tagsArr.count>1) {
                return;
            }
            break;
        default:
            break;
    }
    [self requestDataFromUrl:_listURLs[sender.selectedSegmentIndex]];
}

#pragma mark --UIScrollViewDelegate
//完全结束滚动，设置好显示VisibleRect
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView==_mainScroll) {
        _segCtr.selectedSegmentIndex=_mainScroll.contentOffset.x/KWIDTH;
        [self cahngeCategory:_segCtr];
    }else{
        if (scrollView.contentOffset.y==0) {//刷新
           [self requestDataFromUrl:_listURLs[_segCtr.selectedSegmentIndex]];
        }
    }
}

#pragma mark --UITableViewDataSource+UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView==_latestTable) {
        return _latestArr.count;
    }else if(tableView==_SThotTable){
        return _hotSTArr.count;
    }
    return 10;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell=nil;
    CGFloat ranR=arc4random()%105+150;
    CGFloat ranG=arc4random()%155;
    CGFloat ranB=arc4random()%200+55;
    if (tableView==_latestTable) {
        cell=[tableView dequeueReusableCellWithIdentifier:@"latestCell"];
        if (cell==nil) {
            cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"latestCell"];
        }
        XWSongModel * song=_latestArr[indexPath.row];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:song.UserIcon ?song.UserIcon:song.UpUIcon] placeholderImage:[UIImage imageNamed:@"refresh"]];
        cell.textLabel.text=song.Singer;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%@",song.Name];
    }else if(tableView==_SThotTable){
        cell=[tableView dequeueReusableCellWithIdentifier:@"latestCell"];
        if (cell==nil) {
            cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"latestCell"];
        }
        XWSongModel * song=_hotSTArr[indexPath.row];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:song.UserIcon ?song.UserIcon:song.UpUIcon] placeholderImage:[UIImage imageNamed:@"refresh"]];
        cell.textLabel.text=song.UserName;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%@--%@",song.Name, song.Singer];
    }
    cell.textLabel.textColor=[UIColor colorWithRed:ranR/255.0 green:ranG/255.0 blue:ranB/255.0 alpha:1];
    cell.detailTextLabel.textColor=[UIColor colorWithRed:ranB/255.0 green:ranG/255.0 blue:ranR/255.0 alpha:1];
    cell.backgroundColor=[UIColor clearColor];
    cell.imageView.clipsToBounds=YES;
    cell.imageView.layer.cornerRadius=22.0;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XWSongModel * song=nil;
    if (tableView==_latestTable) {
        song=_latestArr[indexPath.row];
        
    }else if(tableView==_SThotTable){
       
    }
    [[XWCenterPlayer ShareCenter] RequestToPlaySong:song];
    [self presentViewController:[XWCenterPlayer ShareCenter] animated:YES completion:^{ }];
     NSLog(@"(%d--%d)", (int)indexPath.section,(int)indexPath.row);
}

#pragma mark --UICollectionViewDataSource+UICollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView==_albumCollection) {
        return _albumArr.count;
    }else if(collectionView==_tagsCollection){
        return  _tagsArr.count;
    }
    return 15;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell * cell=nil;
    CGFloat ranR=arc4random()%105+150;
    CGFloat ranG=arc4random()%155;
    CGFloat ranB=arc4random()%200+55;
    if (collectionView==_albumCollection) {
        cell=(XWAlbumCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"albumCell" forIndexPath:indexPath];
        
        XWAlbumModel * album=_albumArr[indexPath.row];
        
        [((XWAlbumCell*)cell).albumCover sd_setImageWithURL:[NSURL URLWithString:album.album_icon] placeholderImage:[UIImage imageNamed:@"refresh.png"]];
        ((XWAlbumCell*)cell).albumCover.clipsToBounds=YES;
        ((XWAlbumCell*)cell).albumCover.layer.cornerRadius=45.0;
        
        ((XWAlbumCell*)cell).albumTitle.text=album.album_name;
        ((XWAlbumCell*)cell).albumTitle.textColor=[UIColor colorWithRed:ranR/255.0 green:ranG/255.0 blue:ranB/255.0 alpha:1];
        
    }else if(collectionView==_tagsCollection){
        cell=(XWtagCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"tagsCell" forIndexPath:indexPath];
        NSDictionary * dic=_tagsArr[indexPath.row];
        ((XWtagCell*)cell).tLabel.text=dic[@"key"];
        ((XWtagCell*)cell).tLabel.font=[UIFont systemFontOfSize:18.0-[dic[@"key"] length]];
        
        ((XWtagCell*)cell).tLabel.textColor=[UIColor colorWithRed:ranR/255.0 green:ranG/255.0 blue:ranB/255.0 alpha:1];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    XWListDetailVC *dVc=[[XWListDetailVC alloc]init];
    if (collectionView==_albumCollection) {
        if (_albumArr.count>indexPath.row) {
            XWAlbumModel * album=_albumArr[indexPath.row];
            dVc.urlString=[NSString stringWithFormat:albumDetailFomatURL , album.album_id];
            dVc.type=0;
        }

    }else if(collectionView==_tagsCollection){
        if (_tagsArr.count>indexPath.row) {
            NSDictionary * dic=_tagsArr[indexPath.row];
            NSString * urlStr=[NSString stringWithFormat:tagDetailFomatURL , dic[@"key"],dic[@"istag"]];
            dVc.urlString=[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            dVc.type=1;
            dVc.title=dic[@"key"];
        }
    }
    [self.navigationController pushViewController:dVc animated:YES];
    NSLog(@"(%d--%d)", (int)indexPath.section,(int)indexPath.row);
}

@end
