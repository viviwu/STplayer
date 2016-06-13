//
//  XWCenterPlayer.m
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import "XWCenterPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "GDataXMLNode.h"
#import "HLPicture.h"

static NSString * const kDownloadCellIdentifier = @"downloadCell";
static NSString * const kURLKey = @"URL";
static NSString * const kNameKey = @"name";

static XWCenterPlayer * playerCenter=nil;

@interface XWCenterPlayer ()<UITableViewDataSource, UITableViewDelegate>
{
//    XWSongModel * _currentSong;
//    NSMutableArray * _playedQueue;
    NSTimer * _timer;
}
@property(nonatomic,assign)CGFloat totalSeconds;//媒体文件总时长
@property(nonatomic,assign)CGFloat currentSeconds;//当前已播放时长

@property (nonatomic, strong) NSMutableArray *currentDownloads;//当前要下载的文件队列

@end

@implementation XWCenterPlayer

- (IBAction)back:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

- (IBAction)skipToProgress:(UISlider*)sender {
    
    CMTime time=_player.currentTime;
    time.value =_playerItem.currentTime.timescale * (_totalSeconds * sender.value);
    //跳转到指定的时间
    [_playerItem seekToTime:time];
}

- (IBAction)playBack:(UIButton *)sender {
    if (_playedQueue.count>=2) {
        [self RequestToPlaySong:_playedQueue[_playedQueue.count-2]];
    }else{
        [self RequestToPlaySong:_playedQueue.lastObject];
    }
    
    NSLog(@"上一曲！");
}

- (IBAction)playOrPause:(UIButton *)sender {
    
    if (sender.selected){
        [_player pause];//暂停
        _playerState=1;
        appDEL.playerSwitchHander(NO);
    }else{
        [_player play];//播放
        _playerState=0;
        appDEL.playerSwitchHander(YES);
    }
    sender.selected=!sender.selected;
}

- (IBAction)playForward:(UIButton *)sender {
    [self RequestToPlaySong:_playedQueue.lastObject];
    NSLog(@"下一曲！");
}

+(XWCenterPlayer*)ShareCenter
{
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        if (!playerCenter) {
            playerCenter=[[XWCenterPlayer alloc]init];
        }
    });
    return playerCenter;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _playerState=1;
        _playedQueue=[NSMutableArray array];
        
        [self setAudioSession];//后台播放／锁屏播放
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
    }
    return self;
}
-(BOOL)canBecomeFirstResponder{
    return YES;// default is NO
}


-(void)remoteControlReceivedWithEvent:(UIEvent *)event{
    
    //if it is a remote control event handle it correctly UIEventSubtypeMotionShake
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
            {
                [self playOrPause:_playOrPauseBTN];//耳机🎧点击线控
                NSLog(@"UIEventSubtypeRemoteControlTogglePlayPause...");
                break;
            }
            case UIEventSubtypeRemoteControlPlay:
            {
                [self playOrPause:_playOrPauseBTN];
                NSLog(@"UIEventSubtypeRemoteControlPlay...");
                break;
            }
            case UIEventSubtypeRemoteControlPause:
            {
                [self playOrPause:_playOrPauseBTN];
                NSLog(@"UIEventSubtypeRemoteControlPause...");
                break;
            }
            case UIEventSubtypeRemoteControlStop:
            {
                NSLog(@"UIEventSubtypeRemoteControlStop...");
                break;
            }
            case UIEventSubtypeRemoteControlNextTrack:
            {
                [self RequestToPlaySong:_playedQueue.lastObject];
                NSLog(@"UIEventSubtypeRemoteControlNextTrack...");
                break;
            }
            case UIEventSubtypeRemoteControlPreviousTrack:
            {
                if (_playedQueue.count>=2) {
                    [self RequestToPlaySong:_playedQueue[_playedQueue.count-2]];
                }else{
                    [self RequestToPlaySong:_playedQueue.lastObject];
                }
                NSLog(@"UIEventSubtypeRemoteControlPreviousTrack...");
                break;
            }
            default:
                break;
        }
        
    }
    
}

//后台申请设置
-(void)setAudioSession{
    //Setting the audio category to allow playback when the screen locks or when the Ring/Silent switch is set to silent.
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!success) { /* handle the error condition */  }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    if (!success) { /* handle the error condition */  }
    //这种方式后台，可以连续播放非网络请求歌曲。遇到网络请求歌曲就废，需要后台申请task
    /*
     * AudioSessionInitialize用于处理中断处理，
     * AVAudioSession主要调用setCategory和setActive方法来进行设置，
     * AVAudioSessionCategoryPlayback一般用于支持后台播放
     */
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    //End recieving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"WP1.jpg"]];
    
    [_playOrPauseBTN setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [_playOrPauseBTN setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateSelected];
    
    _currentDownloads = [NSMutableArray new];

    _tableView.backgroundColor=[UIColor clearColor];
    _downloadBTBN.hidden=YES;

}

-(void)playerPlay:(NSURL*)resourceURL
{
    //不管有没有监听，先统一移除了再说
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"resourceURL==%@", resourceURL);
    if (resourceURL==nil) {
        return;
    }
    if (_player) {
        if (_playerState==0) [_player pause];
        _player=nil;
    }
    if (_playerItem) _playerItem=nil;

    _playerItem=[[AVPlayerItem alloc]initWithURL:resourceURL];
//    _player=[[AVPlayer alloc]initWithURL:resourceURL];
    _player=[[AVPlayer alloc]initWithPlayerItem:_playerItem];
    
    //只有播放装载完成(状态为AVPlayerItemStatusReadyToPlay)之后才能获取总时间
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew| NSKeyValueObservingOptionOld context:nil];// 监听status属性
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    
    [_player play];
    _playerState=0;
    _player.volume=0.5;
    _playOrPauseBTN.selected=YES;
    appDEL.playerSwitchHander(YES);
}

-(void)moviePlayDidEnd:(AVPlayerItem*)playItem
{
    NSLog(@"------moviePlayDidEnd------");
}

//监听_playerItem的status属性
#if 0
CMTimeMake("value:当前视频位于哪一帧", "TimeScale帧率");
value/TimeScale = seconds;    //把CMTime转化为秒
#endif

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //AVPlayerItem *playerItem = (AVPlayerItem *)object;//self.playItem
    if ([keyPath isEqualToString:@"status"]){
        
        if ([change[NSKeyValueChangeNewKey] integerValue] == AVPlayerItemStatusReadyToPlay)  //可以播放状态：
        {
            _downloadBTBN.hidden=NO;//可以下载了
            [_playedQueue addObject:_currentSong];//记录播放列表
            
            _totalSeconds =(CGFloat)_playerItem.duration.value / _playerItem.duration.timescale; // 播放时长 s
            
            _totalTime.text=[self convertTime:_totalSeconds];//转化为时间
            
            //解决循环引用问题:
            __weak XWCenterPlayer * weakSelf=self;
            [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time){
                //获取当前播放事件
                CGFloat currSeconds=(CGFloat)weakSelf.playerItem.currentTime.value / weakSelf.playerItem.currentTime.timescale;
                //赋值以显示：
                weakSelf.currentTime.text=[weakSelf convertTime:currSeconds];
                weakSelf.playerSlider.value=currSeconds/weakSelf.totalSeconds;
                _currentSeconds=currSeconds;
                
                [weakSelf configNowPlayingInfoCenter];//配置锁屏播放显示的信息
                appDEL.list.PlayerRotationHander();
            }];
        }else if ([_playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        //NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.fetchProgress setProgress:timeInterval / totalDuration animated:YES];
    }
    
}


//设置锁屏状态，显示的歌曲信息
-(void)configNowPlayingInfoCenter{
    
    if (NSClassFromString(@"MPNowPlayingInfoCenter"))
    {
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        [songInfo setObject:_currentSong.Name forKey:MPMediaItemPropertyTitle];
        [songInfo setObject:_currentSong.Singer  forKey:MPMediaItemPropertyArtist];
        [songInfo setObject:_currentSong.Album forKey:MPMediaItemPropertyAlbumTitle];
        //加作品封面:
        UIImage *image = [UIImage imageNamed:@"CD0.jpg"];
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
        [songInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
        //音乐剩余时长
        [songInfo setObject:[NSNumber numberWithDouble:_totalSeconds-_currentSeconds] forKey:MPMediaItemPropertyPlaybackDuration];
        
        //音乐当前播放时间 这个要根据播放进度回调实时修改
        [songInfo setObject:[NSNumber numberWithDouble:_currentSeconds] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        
        //设置锁屏状态下屏幕显示播放音乐信息
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (!_timer) {
//        _timer=[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    }
}


-(void)RequestToPlaySong:(XWSongModel * )song
{

//    NSString *name=[NSString stringWithFormat:@"%@.mp3",song.ID];
    NSString *name=[NSString stringWithFormat:@"%@.mp3",song.Name];
    NSString *filePath =[kDownloadPath stringByAppendingPathComponent:name];
    NSLog(@"filePath==%@",filePath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSString *itemURL=[NSString stringWithFormat:itemFomatURL,song.ID];
        
        AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager GET:itemURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject){
            //NSString * resString=[[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            //NSLog(@"resString==%@", resString);
            //GDataXMLDocument *doc=[[GDataXMLDocument alloc]initWithXMLString:resString options:0 error:&error];
            NSError *error=nil;
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:responseObject options:0 error:&error];
            GDataXMLElement *rootElement = [doc rootElement];
            GDataXMLElement *urlEle=[[rootElement elementsForName:@"url"] objectAtIndex:0];
            NSString * url=[urlEle stringValue];
            if (url==nil) {
                [self ShowAlartMessage:nil Infomation:@"所点资源不存在！"];
                return ;
            }
            song.onlineURL=url;
            //NSLog(@"name==%@;  singer==%@",[[[rootElement elementsForName:@"song_name"] objectAtIndex:0] stringValue], [[[rootElement elementsForName:@"singer_name"] objectAtIndex:0] stringValue]);
            
            _currentSong=nil;
            _currentSong=song;
            _currentSong.URL=[NSURL URLWithString:url];
            _currentSong.filePath=filePath;
            [self playerPlay:[NSURL URLWithString:url]];
            
        }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }else{
        NSURL * URL=[NSURL URLWithString:[[NSString stringWithFormat:@"file:///%@", filePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        _currentSong=nil;
        _currentSong=song;
        _currentSong.filePath=filePath;
        _currentSong.URL=URL;
        [self playerPlay:URL];
    }
}

-(void)ShowAlartMessage:(NSString*)Title Infomation:(NSString*)info{
    if(Title==nil){
        Title=@"抱歉";
    }
    UIAlertView * alert=[[UIAlertView alloc]initWithTitle:Title message:info delegate:nil cancelButtonTitle:@"稍后或试试别的！" otherButtonTitles: nil];
    [alert show];
}

#pragma mark --downloadCurrentSong
- (IBAction)downloadCurrentSong:(UIButton *)sender {
    
    NSString * fileName=[NSString stringWithFormat:@"%@.mp3", _currentSong.Name];
    NSString *filePath =[kDownloadPath stringByAppendingPathComponent:fileName];
    NSLog(@"filePath==%@",filePath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        TCBlobDownloader *downloader=[[TCBlobDownloader alloc]initWithURL:_currentSong.URL downloadPath:kDownloadPath delegate:self];
        [downloader  setFileName:fileName];
        NSLog(@"---%@/%@", kDownloadPath,fileName);
        
        [self.currentDownloads addObject:downloader];
        
        [[TCBlobDownloadManager sharedInstance] startDownload:downloader];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]   withRowAnimation:UITableViewRowAnimationAutomatic];
    }else{
        [self ShowAlartMessage:@"无需再重复下载啦" Infomation:@"你忘了我们之前不是下载过这首歌了吗？好听就多听遍😄！"];
    }
}

-(void)downloadSong:(XWSongModel*)song
{
    
    
}

- (NSString *)subtitleForDownload:(TCBlobDownloader *)download
{
    NSString *stateString;
    
    switch (download.state) {
        case TCBlobDownloadStateReady:
            stateString = @"Ready";
            break;
        case TCBlobDownloadStateDownloading:
            stateString = @"Downloading";
            break;
        case TCBlobDownloadStateDone:
            stateString = @"Done";
            break;
        case TCBlobDownloadStateCancelled:
            stateString = @"Cancelled";
            break;
        case TCBlobDownloadStateFailed:
            stateString = @"Failed";
            break;
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%i%% • %lis left • State: %@",
            (int)(download.progress * 100),
            (long)download.remainingTime,
            stateString];
}


#pragma mark - TCBlobDownloader Delegate

- (void)download:(TCBlobDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile
{
    NSLog(@"id%f--FINISHED",blobDownload.progress);
    NSInteger index = [self.currentDownloads indexOfObject:blobDownload];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index   inSection:0]];
    
    [cell.detailTextLabel setText:[self subtitleForDownload:blobDownload]];
}

- (void)download:(TCBlobDownloader *)blobDownload
  didReceiveData:(uint64_t)receivedLength
         onTotal:(uint64_t)totalLength
        progress:(float)progress
{
    NSInteger index = [self.currentDownloads indexOfObject:blobDownload];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index
                                                                                     inSection:0]];
    [cell.detailTextLabel setText:[self subtitleForDownload:blobDownload]];
}

- (void)download:(TCBlobDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response
{
    NSInteger index = [self.currentDownloads indexOfObject:blobDownload];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index  inSection:0]];
    
    [cell.detailTextLabel setText:[self subtitleForDownload:blobDownload]];
}

- (void)download:(TCBlobDownloader *)blobDownload didStopWithError:(NSError *)error
{
    NSInteger index = [self.currentDownloads indexOfObject:blobDownload];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index  inSection:0]];
    
    [cell.detailTextLabel setText:[self subtitleForDownload:blobDownload]];
}

#pragma mark - UITableView Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCBlobDownloader *download = self.currentDownloads[indexPath.row];
    NSString *filepath=[[NSString stringWithFormat:@"file:///%@/%@",kDownloadPath,download.fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL * pathURL=[NSURL URLWithString:filepath];
//    NSLog(@"%@", pathURL);
    if (pathURL) {
        [self playerPlay:pathURL];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Cancel";
}
#pragma mark- UITableViewDataSource, UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentDownloads.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDownloadCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle   reuseIdentifier:kDownloadCellIdentifier];
    }
    
    TCBlobDownloader *download = self.currentDownloads[indexPath.row];
    cell.textLabel.textColor=[UIColor yellowColor];
    [cell.textLabel setText:download.fileName];
    [cell.textLabel setFont:[UIFont systemFontOfSize:10.f]];
    [cell.detailTextLabel setText:[self subtitleForDownload:download]];
    
    cell.backgroundColor=[UIColor clearColor];
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TCBlobDownloader *download = self.currentDownloads[indexPath.row];
        [download cancelDownloadAndRemoveFile:YES];
        
        NSInteger index = [self.currentDownloads indexOfObject:download];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [cell.detailTextLabel setText:[self subtitleForDownload:download]];
        
        [cell setEditing:NO animated:YES];
    }
}


#pragma mark - Internal Methods

- (void)dismiss:(id)sender
{
    [[TCBlobDownloadManager sharedInstance] cancelAllDownloadsAndRemoveFiles:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showAddDownloadAlert:(id)sender
{
    UIAlertView *addAlertView = [[UIAlertView alloc] initWithTitle:@"Add Download"  message:nil   delegate:self cancelButtonTitle:@"Cancel"    otherButtonTitles:@"Add this URL", @"~ Multiple Test Downloads ~", nil];
    [addAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    UITextField *textField = [addAlertView textFieldAtIndex:0];
    [textField setPlaceholder:@"http://"];
    
    [addAlertView show];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}


- (NSTimeInterval)availableDuration {
    
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (NSString *)convertTime:(CGFloat)second{
    NSString *showtimeNew=nil;
#if 0
    //方法一
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
#elif 1
    //方法二：
    showtimeNew=[NSString stringWithFormat:@"%02d:%02d",(int)second/60,(int)second%60];
#endif
    return showtimeNew;
}

- (void)customplayerSlider:(CMTime)duration {
    
    self.playerSlider.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.playerSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.playerSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

@end
