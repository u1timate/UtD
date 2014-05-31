//
//  UTFinderEntity.m
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTFinderEntity.h"

@implementation UTFinderEntity

- (id)init {
    if (self = [super init]) {
        self.fileName = @"NULL";
        self.filePath = @"NULL";
    }
    return self;
}

- (void)setFilePath:(NSString *)filePath {
    if (_filePath != filePath) {
        _filePath = filePath;
        _MIMEType = [self typeForPath:filePath];
    }
}

- (NSString *)typeForPath:(NSString *)filePath {
    CFStringRef fileExtension = (__bridge CFStringRef)[filePath pathExtension];
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    NSString *MIMETypeString = (__bridge_transfer NSString *)MIMEType;
    
    return MIMETypeString;
}

@end
