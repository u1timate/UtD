//
//  UTFinderEntity.h
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MobileCoreServices/MobileCoreServices.h>

@interface UTFinderEntity : NSObject

@property (copy, nonatomic) NSString *fileName;

@property (copy, nonatomic) NSString *fileAttrs;

@property (copy, nonatomic) NSString *filePath;

@property (readonly, nonatomic) UTFinderFileType type;

@property (readonly, nonatomic) UIImage *typeImage;

+ (NSArray *)generateFilesInPath:(NSString *)path;

+ (UIImage *)imageWithFilePath:(NSString *)filePath scaledToWidth:(float)i_width;

@end
