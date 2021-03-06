//
//  UTFinderEntity.m
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTFinderEntity.h"

@implementation UTFinderEntity

- (void)setFilePath:(NSString *)filePath {
    if (_filePath != filePath) {
        _filePath = filePath;
        _type = [self typeForPath:filePath];
        _typeImage = [self imageForUTType:_type];
    }
}

- (UIImage *)imageForUTType:(UTFinderFileType)type {
    switch (type) {
            
        case UTFinderGoUpType:
            return [UIImage imageNamed:@"Up"];
            break;
            
        case UTFinderFolderType:
            return [UIImage imageNamed:@"folder"];
            break;
            
        case UTFinderImageType:
            return [UIImage imageNamed:@"images"];
            break;
            
        case UTFinderAudioType:
            return [UIImage imageNamed:@"music"];
            break;
            
        case UTFinderMovieType:
            return [UIImage imageNamed:@"movie"];
            break;
        
        case UTFinderTextType:
            return [UIImage imageNamed:@"text"];
            
        default:
            return [UIImage imageNamed:@"unknown"];
            break;
    }
}

- (UTFinderFileType)typeForPath:(NSString *)path{
    
    if ([path isEqualToString:@"Up"]) {
        return UTFinderGoUpType;
    }
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        
    if (isDirectory) {
        return UTFinderFolderType;
    } else {
        
        CFStringRef fileExtension = (__bridge CFStringRef) [path pathExtension];
        
        CFStringRef fileUTI =  UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
        
        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) return UTFinderImageType;
        else if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) return UTFinderAudioType;
        else if (UTTypeConformsTo(fileUTI, kUTTypeText)) return UTFinderTextType;
        else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) return UTFinderMovieType;
        else return UTFinderUnknownType;
    }
}

+ (NSArray *)generateFilesInPath:(NSString *)path {
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *e = [fileManager enumeratorAtPath:path];
    
    NSString *file;
    
    while (file = [e nextObject]) {
        [e skipDescendants];
        UTFinderEntity *entity = [[UTFinderEntity alloc] init];
        entity.fileName = file;
        entity.filePath = [path stringByAppendingFormat:@"/%@", file];
#warning 后面要改成显示文件修改时间等信息
        entity.fileAttrs = @"Some Attributes";
        [array addObject:entity];
    }
    return array;
}

+ (UIImage*)imageWithFilePath:(NSString *)filePath scaledToWidth:(float)i_width {
    
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:filePath];
    
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
