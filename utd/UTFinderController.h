//
//  UTFinderController.h
//  utd
//
//  Created by 徐磊 on 14-6-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MWPhotoBrowser.h"

@interface UTFinderController : NSObject <MWPhotoBrowserDelegate, UIToolbarDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UISegmentedControl *segment;
@property (strong, nonatomic) UINavigationController *navigationController;

@property (strong, nonatomic) NSMutableArray *objects;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *dirImages;
@property (strong, nonatomic) NSMutableArray *selectedItems;
@property (strong, nonatomic) NSMutableArray *selectedItemsFilePaths;

@property (assign, nonatomic) BOOL lockForAction;
@property (assign, nonatomic) BOOL isEditing;

@property (copy, nonatomic) NSString *selectedItemPath;
@property (copy, nonatomic) NSString *documentPath;

@property (assign, nonatomic) UTActionIdentifier action;

- (id)initWithFinderStyle:(UTFinderStyle)style;
- (void)addNewDirectory:(id)sender;
- (void)layoutTitleViewForSegment:(BOOL)seg;
- (void)shareAction:(id)sender;
- (void)showImageBrowserAtIndex:(NSUInteger)index;
- (void)showHudWithMessage:(NSString *)message iconName:(NSString *)name;
- (void)changeStyle:(id)sender;

BOOL checkReachableAtPath(NSString *path);

//ToolBar Action
- (void)deleteItems:(id)sender;
- (void)moveItems:(id)sender;
- (void)copyItems:(id)sender;
- (void)renameItems:(id)sender;
- (void)operateItems:(id)sender action:(UTActionIdentifier)action;

@end
