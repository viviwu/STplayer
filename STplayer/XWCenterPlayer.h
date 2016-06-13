//
//  XWCenterPlayer.h
//  STplayer
//
//  Created by qway on 15/8/11.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XWSongModel.h"
#import "TCBlobDownload.h"

@interface XWCenterPlayer : UIViewController<UIAlertViewDelegate, TCBlobDownloaderDelegate>

{
    AVPlayer *_player;//可以播放本地或者网络、🎵或者视频
}
@property(nonatomic, strong) AVPlayer * player;
@property(nonatomic,strong)AVPlayerItem * playerItem;//播放信息
@property(nonatomic, assign) BOOL playerState;//0:播放／1:非播放

@property(nonatomic, strong) XWSongModel * currentSong;
@property(nonatomic, strong) NSMutableArray *playedQueue;

@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UISlider *playerSlider;
@property (weak, nonatomic) IBOutlet UIProgressView *fetchProgress;

@property (weak, nonatomic) IBOutlet UIButton *playBackBTN;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBTN;
@property (weak, nonatomic) IBOutlet UIButton *playForwardBTN;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)back:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *downloadBTBN;
- (IBAction)downloadCurrentSong:(UIButton *)sender;

- (IBAction)skipToProgress:(id)sender;
- (IBAction)playBack:(id)sender;
- (IBAction)playOrPause:(id)sender;
- (IBAction)playForward:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;

-(void)playerPlay:(NSURL*)resourceURL;

+(XWCenterPlayer*)ShareCenter;
-(void)RequestToPlaySong:(XWSongModel * )song;

@end
