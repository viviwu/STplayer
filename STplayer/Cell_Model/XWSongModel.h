//
//  XWSongModel.h
//  XW_Player
//
//  Created by qway on 15/6/25.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XWSongModel : NSObject
//用户
@property(nonatomic,copy)NSString * UserID;
@property(nonatomic,copy)NSString * UserName;
@property(nonatomic,copy)NSString * UserIcon;

//推荐歌曲
@property(nonatomic,copy)NSString * ID;
@property(nonatomic,copy)NSString * onlineURL;
@property(nonatomic,copy)NSString * Name;
@property(nonatomic,copy)NSString * UpUName;
@property(nonatomic,copy)NSString * UpUIcon;
@property(nonatomic,copy)NSString * Singer;

@property(nonatomic,copy)NSString * Click;
@property(nonatomic,copy)NSString * GradeNum;
@property(nonatomic,copy)NSString * FavNum;

@property(nonatomic,copy)NSString * RateDT;
@property(nonatomic,copy)NSString * RateUID;
@property(nonatomic,copy)NSString * RateUName;

@property(nonatomic,copy)NSString * DevType;

@property(nonatomic,copy)NSString *Album;//所属专辑名

@property(nonatomic,copy)NSURL * URL;//下载地址
@property(nonatomic,copy)NSString * filePath;//本地存放路径

@end
