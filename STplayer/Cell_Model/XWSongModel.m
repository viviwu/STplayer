//
//  XWSongModel.m
//  XW_Player
//
//  Created by qway on 15/6/25.
//  Copyright (c) 2015年 XW. All rights reserved.
//

#import "XWSongModel.h"

@implementation XWSongModel

-(id)init{
    self=[super init];
    if (self) {
        _Album=@"vivi随机";
        _Name=@"也许好听的歌";
        _Singer=@"某未知歌手";
    }
    return self;
}

@end
