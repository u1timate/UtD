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

@property (copy, nonatomic) NSString *filePath;

@property (readonly, nonatomic) BOOL isDirectory;

@property (readonly, nonatomic) NSString *MIMEType;

@end
