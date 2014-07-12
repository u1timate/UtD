//
//  UTFinderController.m
//  utd
//
//  Created by 徐磊 on 14-6-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTFinderController.h"

#import "UTFinderCollectionController.h"
#import "UTFinderTableViewController.h"

#import "UTFinderEntity.h"
#import "LGViewHUD.h"
#import "UTAlertViewDelegate.h"

@interface UTFinderController ()

@property (weak, nonatomic) UIActivityViewController *activityViewController;


@end

@implementation UTFinderController {
    UTFinderStyle _currentFinderStyle;
    NSString *_currentOriginalFilePath;
    NSString *_toFilePath;
    dispatch_queue_t _actionQueue;
}

- (id)initWithFinderStyle:(UTFinderStyle)style {
    self = [super init];
    if (self) {
        
        //变量初始化
        _dirImages = [[NSMutableArray alloc] initWithCapacity:0];
        _objects = [[NSMutableArray alloc] initWithCapacity:0];
        _photos = [[NSMutableArray alloc] initWithCapacity:0];
        _selectedItems = [[NSMutableArray alloc] initWithCapacity:0];
        _selectedItemsFilePaths = [[NSMutableArray alloc] initWithCapacity:0];
        
        _lockForAction = NO;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _documentPath = [paths firstObject];
        
        _selectedItemPath = _documentPath;
        
        _currentFinderStyle = style;
        
        _segment.selectedSegmentIndex = style;
        
        if (style ==  UTFinderLayoutCollectionStyle) {
            
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
            layout.itemSize = CGSizeMake(80, 100);
            layout.minimumLineSpacing = 0.0f;
            layout.minimumInteritemSpacing = 0.0f;
            
            UTFinderCollectionController *collectionController = [[UTFinderCollectionController alloc] initWithCollectionViewLayout:layout];
            
            _navigationController = [[UINavigationController alloc] initWithRootViewController:collectionController];
            
            collectionController.myParentController = self;
            
        } else {
            
            UTFinderTableViewController *tableController = [[UTFinderTableViewController alloc] initWithStyle:UITableViewStylePlain];
            
            _navigationController = [[UINavigationController alloc] initWithRootViewController:tableController];
            
            tableController.myParentController = self;
            
        }
    }
    return self;
}

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kUTDefaultFinderStyle : [NSNumber numberWithInteger:UTFinderLayoutTableStyle],
                                                              kUTDefaultPullToRefresh: @YES,
                                                              kUTDefaultShowImagePreview: @NO}];
}

- (void)awakeFromNib {
    
    [self layoutTitleViewForSegment:YES];
    
}

#pragma mark - IBAction

- (void)layoutTitleViewForSegment:(BOOL)seg {
    if (seg) {
        
        _textLabel = nil;
        
        NSArray *itemArray = @[NSLocalizedString(@"Table", nil), NSLocalizedString(@"Collection", nil)];
        _segment = [[UISegmentedControl alloc] initWithItems:itemArray];
        _segment.frame = CGRectMake(0, 0, 150, 30);
        _segment.segmentedControlStyle = UISegmentedControlStylePlain;
        [[_navigationController topViewController] navigationItem].titleView = _segment;
        
        [_segment addTarget:self action:@selector(changeStyle:) forControlEvents: UIControlEventValueChanged];
        _segment.selectedSegmentIndex = 0;
        
    } else {
        
        _segment = nil;
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
        
        _textLabel.textAlignment = NSTextAlignmentCenter;
        
        [[_navigationController topViewController] navigationItem].titleView = _textLabel;
        
        NSUInteger count = 0;
        
        _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        
        
    }
    
    self.segment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kUTDefaultFinderStyle];
    
}

- (void)changeStyle:(id)sender {
    _currentFinderStyle = (UTFinderStyle)[sender selectedSegmentIndex];
    
    [[NSUserDefaults standardUserDefaults] setInteger:_currentFinderStyle forKey:kUTDefaultFinderStyle];
    
    if (_currentFinderStyle ==  UTFinderLayoutCollectionStyle) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.itemSize = CGSizeMake(80, 100);
        layout.minimumLineSpacing = 0.0f;
        layout.minimumInteritemSpacing = 0.0f;
        
        UTFinderCollectionController *collectionController = [[UTFinderCollectionController alloc] initWithCollectionViewLayout:layout];
        
        [_navigationController setViewControllers:@[collectionController] animated:YES];
        
        collectionController.myParentController = self;
        
    } else {
        
        UTFinderTableViewController *tableController = [[UTFinderTableViewController alloc] initWithStyle:UITableViewStylePlain];
        
        [_navigationController setViewControllers:@[tableController] animated:YES];
        
        tableController.myParentController = self;
        
    }
}



#pragma mark - Basic Functions

BOOL checkReachableAtPath(NSString *path) {
    NSURL *url = [NSURL fileURLWithPath:path];
    int a = [url checkResourceIsReachableAndReturnError:nil];
    return a;
}

- (void)setLockForAction:(BOOL)lockForAction {
    
    _lockForAction = lockForAction;
    
    [self lockAction:lockForAction];
}

- (void)lockAction:(BOOL)locked {
    _navigationController.navigationItem.leftBarButtonItem.enabled = !locked;
    _navigationController.navigationItem.rightBarButtonItem.enabled = !locked;
    self.segment.enabled = !locked;
    
    for (UIBarButtonItem *item in [self currentToolBar].items) {
        item.enabled = !locked;
    }
}

- (void)showHudWithMessage:(NSString *)message iconName:(NSString *)name {
    LGViewHUD *hud = [LGViewHUD defaultHUD];
    hud.bottomText = message;
    [hud showInView:_navigationController.view withAnimation:HUDAnimationNone];
    
    if (name) {
        hud.image = [UIImage imageNamed:name];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hideWithAnimation:HUDAnimationHideFadeOut];
    });
    
}

#pragma mark Toolbar Edit

- (UIToolbar *)currentToolBar {
    if ([_navigationController.topViewController.description isEqualToString:@"UTFinderCollectionController"]) {
        return [(UTFinderCollectionController *)_navigationController.topViewController editingToolbar];
    }
    return [(UTFinderTableViewController *)_navigationController.topViewController editingToolbar];
}

- (void)addNewDirectory:(id)sender {
    if (checkReachableAtPath(_selectedItemPath)) {
        UIAlertView *alertview = [[UIAlertView alloc] init];
        alertview.alertViewStyle = UIAlertViewStylePlainTextInput;
        alertview.message = NSLocalizedString(@"Please input new folder name", nil);
        [alertview addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alertview addButtonWithTitle:NSLocalizedString(@"Create", nil)];
        alertview.cancelButtonIndex = 0;
        [[alertview textFieldAtIndex:0] setText:NSLocalizedString(@"Untitled Folder", nil)];
        [UTAlertViewDelegate showAlertView:alertview withCallback:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                NSError *error;
                NSString *dirname = [[alertview textFieldAtIndex:0] text];
                [[NSFileManager defaultManager] createDirectoryAtPath:[_documentPath stringByAppendingFormat:@"/%@", dirname] withIntermediateDirectories:YES attributes:nil error:&error];
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something goes wrong when perform file action. Please check permission or contact us.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                    [alert show];
                }
                
                UTFinderEntity *entity = [[UTFinderEntity alloc] init];
                
                entity.filePath = [_documentPath stringByAppendingFormat:@"/%@", dirname];
                
                [_objects addObject:entity];
                
                switch (_currentFinderStyle) {
                    case UTFinderLayoutCollectionStyle:
                        [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:[(UTFinderCollectionController *)_navigationController.topViewController collectionView].visibleCells.count inSection:0]]];
                        break;
                        
                    default:
                        [[(UTFinderTableViewController *)_navigationController.topViewController tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[(UTFinderTableViewController *)_navigationController.topViewController tableView].visibleCells.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        break;
                }
                
            }
        }];
    }
}

- (void)deleteItems:(id)sender {
    
    _action = UTActionDelete;
    
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.tag = _action;
    if (_selectedItems.count > 1) {
        sheet.title = [NSString stringWithFormat:NSLocalizedString(@"Do you want to delete %lu selected items?", nil), _selectedItems.count];
    } else {
        sheet.title = [NSString stringWithFormat:NSLocalizedString(@"Do you want to delete %lu selected item?", nil), _selectedItems.count];
    }
    
    sheet.delegate = self;
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    [sheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    
    sheet.cancelButtonIndex = 1;
    
    sheet.destructiveButtonIndex = 0;
    
    [sheet showFromToolbar:[self currentToolBar]];
}

- (void)moveItems:(id)sender {
    _action = UTActionMove;
    [self operateItems:sender action:UTActionMove];
}

- (void)copyItems:(id)sender {
    _action = UTActionCopy;
    [self operateItems:sender action:UTActionCopy];
}

- (void)renameItems:(id)sender {
    [self renameBatch];
}

- (void)operateItems:(id)sender action:(UTActionIdentifier)action {
    
    if (_selectedItems.count < 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You must choose at least one item.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        if (_currentFinderStyle == UTFinderLayoutTableStyle) {
            [(UTFinderTableViewController *)_navigationController.topViewController setEditing:NO animated:YES];
        }
        return;
    }
    
    if (![[sender title] isEqualToString:NSLocalizedString(@"Put", nil)]) {
        
        _lockForAction = YES;
        [sender setTitle:NSLocalizedString(@"Put", nil)];
        _textLabel.text = NSLocalizedString(@"Choose Destination", nil);
        
        _isEditing = NO;
        
        switch (_currentFinderStyle) {
            case UTFinderLayoutCollectionStyle:
                [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] reloadItemsAtIndexPaths:[[(UTFinderCollectionController *)_navigationController.topViewController collectionView] indexPathsForVisibleItems]];
                break;
                
            default:
                [(UTFinderTableViewController *)_navigationController.topViewController setEditing:NO animated:YES];
                
                break;
        }
        
        switch (action) {
            case UTActionMove:
                [(UIBarButtonItem *)[self currentToolBar].items[0] setEnabled:NO];
                [(UIBarButtonItem *)[self currentToolBar].items[4] setEnabled:NO];
                [(UIBarButtonItem *)[self currentToolBar].items[6] setEnabled:NO];
                break;
                
            case UTActionCopy:
                [(UIBarButtonItem *)[self currentToolBar].items[0] setEnabled:NO];
                [(UIBarButtonItem *)[self currentToolBar].items[2] setEnabled:NO];
                [(UIBarButtonItem *)[self currentToolBar].items[6] setEnabled:NO];
                break;
                
            default:
                break;
        }
    } else {
        
        NSString *text = @"";
        
        if (action == UTActionMove) {
            text = NSLocalizedString(@"move", nil);
        } else if (action == UTActionCopy) {
            text = NSLocalizedString(@"copy", nil);
        }
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        sheet.tag = action;
        if (_selectedItems.count > 1) {
            sheet.title = [NSString stringWithFormat:NSLocalizedString(@"Do you want to %@ %lu selected items?", nil), text, _selectedItems.count];
        } else {
            sheet.title = [NSString stringWithFormat:NSLocalizedString(@"Do you want to %@ %lu selected item?", nil), text, _selectedItems.count];
        }
        
        sheet.delegate = self;
        sheet.actionSheetStyle = UIActionSheetStyleDefault;
        
        [sheet addButtonWithTitle:[[[text substringToIndex:1] uppercaseString] stringByAppendingString:[text substringFromIndex:1]]];
        [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        
        sheet.cancelButtonIndex = 1;
        
        [sheet showFromToolbar:[self currentToolBar]];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == UTActionDuplicatedFile) {
        if (buttonIndex != actionSheet.cancelButtonIndex && buttonIndex != UTDuplicateKeepOriginalFile) {
            NSError *error;
            
            __block BOOL doNotAct = NO;
            
            if (buttonIndex == UTDuplicateOverWrite) {
                [[NSFileManager defaultManager] removeItemAtPath:_toFilePath error:&error];
                
            } else if (buttonIndex == UTDuplicateKeepBoth) {
                NSString *fileName = [[_currentOriginalFilePath componentsSeparatedByString:@"/"] lastObject];
                NSArray *array = [fileName componentsSeparatedByString:@"."];
                NSString *newName = [[array[0] stringByAppendingString:NSLocalizedString(@"-copied", nil)] stringByAppendingFormat:@".%@", array[1]];
                _toFilePath = [[_toFilePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", newName];
                
            } else if (buttonIndex == UTDuplicateRename) {
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                alertView.message = NSLocalizedString(@"Please input a new name", nil);
                if (_action == UTActionCopy) {
                    [alertView addButtonWithTitle:NSLocalizedString(@"Copy", nil)];
                } else if (_action == UTActionMove) {
                    [alertView addButtonWithTitle:NSLocalizedString(@"Move", nil)];
                }
                [alertView addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                alertView.cancelButtonIndex = 1;
                
                [UTAlertViewDelegate showAlertView:alertView withCallback:^(NSInteger buttonIndex) {
                    if (buttonIndex != alertView.cancelButtonIndex) {
                        _toFilePath = [[_toFilePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", [[alertView textFieldAtIndex:0] text]];
                    } else {
                        doNotAct = YES;
                    }
                }];
                
            }
            
            if (!doNotAct) {
                
                if (_action == UTActionMove) {
                    [[NSFileManager defaultManager] moveItemAtPath:_currentOriginalFilePath toPath:_toFilePath error:&error];
                } else if (_action == UTActionCopy) {
                    [[NSFileManager defaultManager] copyItemAtPath:_currentOriginalFilePath toPath:_toFilePath error:&error];
                }
            }
            dispatch_resume(_actionQueue);
        } else if (buttonIndex == actionSheet.cancelButtonIndex) {
            if (_currentFinderStyle == UTFinderLayoutTableStyle) {
                [(UTFinderTableViewController *)_navigationController.topViewController setEditing:NO animated:YES];
            } else if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
                _isEditing = NO;
                [(UTFinderCollectionController *)_navigationController.topViewController setFinderEditing:nil];
            }
        }
    } else {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            
            self.lockForAction = YES;
            __block NSError *error;
            switch (_action) {
                case UTActionDelete: {
                    
                    __block LGViewHUD *hud = [LGViewHUD defaultHUD];
                    hud.bottomText = NSLocalizedString(@"Deleting Files", nil);
                    [hud showInView:_navigationController.view];
                    hud.activityIndicatorOn = YES;
                    hud.displayDuration = 86400.0f;
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        NSMutableArray *indexpaths = [NSMutableArray array];
                        NSMutableArray *objs = [NSMutableArray array];
                        for (NSNumber *index in _selectedItems) {
                            UTFinderEntity *entity = _objects[index.integerValue];
                            [objs addObject:entity];
                            [indexpaths addObject:[NSIndexPath indexPathForRow:index.integerValue inSection:0]];
                        }
                        
                        for (UTFinderEntity *entity in objs) {
                            if (checkReachableAtPath(entity.filePath)) {
                                [[NSFileManager defaultManager] removeItemAtPath:entity.filePath error:&error];
                                if (error) {
                                    NSLog(@"%@", error);
                                    [indexpaths removeObjectAtIndex:[objs indexOfObject:entity]];
                                } else {
                                    [_objects removeObject:entity];
                                }
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            switch (_currentFinderStyle) {
                                case UTFinderLayoutCollectionStyle:
                                    [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] deleteItemsAtIndexPaths:indexpaths];
                                    
                                    [(UTFinderCollectionController *)_navigationController.topViewController setFinderEditing:nil];
                                    
                                    [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] reloadItemsAtIndexPaths:[[(UTFinderCollectionController *)_navigationController.topViewController collectionView] indexPathsForVisibleItems]];
                                    
                                    break;
                                    
                                default:
                                    [[(UTFinderTableViewController *)_navigationController.topViewController tableView] deleteRowsAtIndexPaths:indexpaths withRowAnimation:UITableViewRowAnimationAutomatic];
                                    [(UTFinderTableViewController *)_navigationController.topViewController setEditing:NO animated:YES];
                                    [(UTFinderTableViewController *)_navigationController.topViewController hideToolBar];
                                    
                                    break;
                            }
                            
                            [hud hideWithAnimation:HUDAnimationNone];
                            
                            hud = nil;
                            [self showHudWithMessage:NSLocalizedString(@"Deleted", nil) iconName:@"operation_done"];
                            _selectedItems = [[NSMutableArray alloc] initWithCapacity:0];
                            _selectedItemsFilePaths = [[NSMutableArray alloc] initWithCapacity:0];
                            if (_currentFinderStyle == UTFinderLayoutTableStyle && _navigationController.topViewController.navigationItem.rightBarButtonItem == nil) {
                                [_navigationController.topViewController.navigationItem setRightBarButtonItem:_navigationController.topViewController.editButtonItem animated:YES];
                            }
                        });
                        
                    });
                    break;
                }
                    
                case UTActionMove: {
                    
                    __block LGViewHUD *hud = [LGViewHUD defaultHUD];
                    hud.bottomText = NSLocalizedString(@"Moving Files", nil);
                    hud.activityIndicatorOn = YES;
                    [hud showInView:_navigationController.view];
                    
                    _actionQueue = dispatch_queue_create("org.utstudio.utd.action", NULL);
                    
                    dispatch_group_t actionGroup = dispatch_group_create();
                    
                    
                    for (NSString *filePath in _selectedItemsFilePaths) {
                        _currentOriginalFilePath = filePath;
                        NSString *fileName = [[_currentOriginalFilePath componentsSeparatedByString:@"/"] lastObject];
                        _toFilePath = [_selectedItemPath stringByAppendingFormat:@"/%@", fileName];
                        
                        if (checkReachableAtPath(_toFilePath)) {
                            dispatch_suspend(_actionQueue);
                            [self fileDoesExistsAtPath:_toFilePath];
                        }
                        
                        dispatch_group_async(actionGroup, _actionQueue, ^{
                            [[NSFileManager defaultManager] moveItemAtPath:_currentOriginalFilePath toPath:_toFilePath error:&error];
                            
                            if (error) {
                                NSLog(@"%@", error);
                            } else {
                                UTFinderEntity *entity = [[UTFinderEntity alloc] init];
                                
                                entity.filePath = [_selectedItemPath stringByAppendingFormat:@"/%@", fileName];
                                
                                [_objects addObject:entity];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
                                        [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:[(UTFinderCollectionController *)_navigationController.topViewController collectionView].visibleCells.count inSection:0]]];
                                    } else {
                                        [[(UTFinderTableViewController *)_navigationController.topViewController tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[(UTFinderTableViewController *)_navigationController.topViewController tableView].visibleCells.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                    }
                                    
                                });
                            }
                            
                        });
                    }
                    
                    dispatch_group_notify(actionGroup, dispatch_get_main_queue(), ^{
                        [hud hideWithAnimation:HUDAnimationNone];
                        hud = nil;
                        [self showHudWithMessage:NSLocalizedString(@"Moved", nil) iconName:@"operation_done"];
                        
                        if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
                            [(UTFinderCollectionController *)_navigationController.topViewController setFinderEditing:nil];
                        } else {
                            [(UTFinderTableViewController *)_navigationController.topViewController hideToolBar];
                        }
                        
                        _selectedItems = [[NSMutableArray alloc] initWithCapacity:0];
                        _selectedItemsFilePaths = [[NSMutableArray alloc] initWithCapacity:0];
                        //_actionQueue = nil;
                        
                        _lockForAction = NO;
                    });
                    
                    break;
                }
                    
                case UTActionCopy: {
                    
                    __block LGViewHUD *hud = [LGViewHUD defaultHUD];
                    hud.bottomText = NSLocalizedString(@"Copying Files", nil);
                    hud.activityIndicatorOn = YES;
                    [hud showInView:_navigationController.view];
                    
                    _actionQueue = dispatch_queue_create("org.utstudio.utd.action", NULL);
                    
                    dispatch_group_t actionGroup = dispatch_group_create();
                    
                    
                    for (NSString *filePath in _selectedItemsFilePaths) {
                        _currentOriginalFilePath = filePath;
                        NSString *fileName = [[_currentOriginalFilePath componentsSeparatedByString:@"/"] lastObject];
                        _toFilePath = [_selectedItemPath stringByAppendingFormat:@"/%@", fileName];
                        
                        if (checkReachableAtPath(_toFilePath)) {
                            dispatch_suspend(_actionQueue);
                            [self fileDoesExistsAtPath:_toFilePath];
                        }
                        
                        dispatch_group_async(actionGroup, _actionQueue, ^{
                            [[NSFileManager defaultManager] copyItemAtPath:_currentOriginalFilePath toPath:_toFilePath error:&error];
                            
                            if (error) {
                                NSLog(@"%@", error);
                            } else {
                                
                                UTFinderEntity *entity = [[UTFinderEntity alloc] init];
                                
                                entity.filePath = [_selectedItemPath stringByAppendingFormat:@"/%@", fileName];
                                
                                [_objects addObject:entity];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
                                        [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:[(UTFinderCollectionController *)_navigationController.topViewController collectionView].visibleCells.count inSection:0]]];
                                    } else {
                                        [[(UTFinderTableViewController *)_navigationController.topViewController tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[(UTFinderTableViewController *)_navigationController.topViewController tableView].visibleCells.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                    }
                                    
                                });
                            }
                        });
                    }
                    
                    dispatch_group_notify(actionGroup, dispatch_get_main_queue(), ^{
                        [hud hideWithAnimation:HUDAnimationNone];
                        hud = nil;
                        [self showHudWithMessage:NSLocalizedString(@"Copied", nil) iconName:@"operation_done"];
                        
                        if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
                            [(UTFinderCollectionController *)_navigationController.topViewController setFinderEditing:nil];
                        } else {
                            [(UTFinderTableViewController *)_navigationController.topViewController hideToolBar];
                        }
                        
                        _selectedItems = [[NSMutableArray alloc] initWithCapacity:0];
                        _selectedItemsFilePaths = [[NSMutableArray alloc] initWithCapacity:0];
                        //_actionQueue = nil;
                        
                        _lockForAction = NO;
                    });
                    
                    break;
                }
                default:
                    break;
                    
            }
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something goes wrong when perform file action. Please check permission or contact us.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alert show];
            }
            _lockForAction = NO;
        }
    }
}

- (void)fileDoesExistsAtPath:(NSString *)path {
    
    NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = [NSString stringWithFormat:NSLocalizedString(@"File %@ exists in destination directory. How to deal with it?", nil), fileName];
    sheet.delegate = self;
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    sheet.tag = UTActionDuplicatedFile;
    
    [sheet addButtonWithTitle:NSLocalizedString(@"Rename", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Overwrite", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Keep Both", nil)];
    [sheet addButtonWithTitle:NSLocalizedString(@"Skip", nil)];
    
    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    
    sheet.cancelButtonIndex = 4;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [sheet showInView:_navigationController.view];
    });
    
}

#pragma mark - IAP Methods

- (void)renameBatch {
    UIAlertView *alertview = [[UIAlertView alloc] init];
    alertview.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertview.message = NSLocalizedString(@"Please input new name (Multiple file rename rules please refer to help documents)", nil);
    [alertview addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alertview addButtonWithTitle:NSLocalizedString(@"Rename", nil)];
    alertview.cancelButtonIndex = 0;
    [UTAlertViewDelegate showAlertView:alertview withCallback:^(NSInteger buttonIndex) {
        
        if (buttonIndex == 1) {
            NSError *error;
            NSString *dirname = [[alertview textFieldAtIndex:0] text];
            if ([dirname rangeOfString:@"(*)"].location != NSNotFound && [dirname rangeOfString:@"?"].location == NSNotFound) {
                for (int i = 0; i < _selectedItems.count; i++) {
                    UTFinderEntity *entity = [_objects objectAtIndex:[[_selectedItems objectAtIndex:i] integerValue]];
                    NSString *filePath = entity.filePath;
                    NSString *newDir = [dirname stringByReplacingOccurrencesOfString:@"(*)" withString:[NSString stringWithFormat:@"%d", i + 1]];
                    NSString *newPath = [[filePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", newDir];
                    
                    [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newPath error:&error];
                    
                    entity.filePath = newPath;
                    
                    if (error) {
                        NSLog(@"%@", error);
                    }
                }
            } else if ([dirname rangeOfString:@"(*)"].location == NSNotFound && [dirname rangeOfString:@"(?"].location != NSNotFound) {
                
                NSArray *array = [dirname componentsSeparatedByString:@"?"];
                
                NSUInteger count = 0;
                
                for (NSString *a in array) {
                    if ([a isEqualToString:@""]) {
                        count++;
                    }
                }
                
                count++;
                
                NSString *dk = @"(";
                NSString *nfs = @"";
                for (int i = 0; i < count; i++) {
                    dk = [dk stringByAppendingString:@"?"];
                    nfs = [nfs stringByAppendingString:@"0"];
                }
                
                dk = [dk stringByAppendingString:@")"];
                
                for (int i = 0; i < _selectedItems.count; i++) {
                    UTFinderEntity *entity = [_objects objectAtIndex:[[_selectedItems objectAtIndex:i] integerValue]];
                    
                    NSString *filePath = entity.filePath;
                    
                    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                    [nf setPositiveFormat:nfs];
                    NSString *nfString = [nf stringFromNumber:[NSNumber numberWithInt:i + 1]];
                    
                    NSString *newDir = [dirname stringByReplacingOccurrencesOfString:dk withString:nfString];
                    NSString *newPath = [[filePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", newDir];
                    
                    [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newPath error:&error];
                    
                    entity.filePath = newPath;
                    
                    if (error) {
                        NSLog(@"%@", error);
                    }
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please follow U1timate Drop Rename Regular Expression.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alert show];
            }
            
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something goes wrong when perform file action. Please check permission or contact us.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alert show];
            }
            
            switch (_currentFinderStyle) {
                case UTFinderLayoutCollectionStyle:
                    [[(UTFinderCollectionController *)_navigationController.topViewController collectionView] reloadItemsAtIndexPaths:[[(UTFinderCollectionController *)_navigationController.topViewController collectionView] indexPathsForVisibleItems]];
                    [(UTFinderCollectionController *)_navigationController.topViewController setFinderEditing:nil];
                    break;
                    
                default:
                    [[(UTFinderTableViewController *)_navigationController.topViewController tableView] reloadRowsAtIndexPaths:[[(UTFinderTableViewController *)_navigationController.topViewController tableView] indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
                    break;
            }
            
            [self showHudWithMessage:NSLocalizedString(@"Renamed", nil) iconName:@"operation_done"];
        }
    }];
}

- (void)showImageBrowserAtIndex:(NSUInteger)index {
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.alwaysShowControls = NO;
    browser.zoomPhotosToFill = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    browser.wantsFullScreenLayout = YES;
#endif
    browser.enableGrid = NO;
    browser.startOnGrid = NO;
    browser.enableSwipeToDismiss = NO;
    [browser setCurrentPhotoIndex:index];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [_navigationController presentViewController:nc animated:YES completion:nil];
}

- (void)shareAction:(id)sender {
    NSLog(@"Not done");
    
    [self showHudWithMessage:@"Not Done Yet" iconName:@"operation_failed"];
    // Handle default actions
    /*    if (SYSTEM_VERSION_LESS_THAN(@"6")) {
     
     // Old handling of activities with action sheet
     if ([MFMailComposeViewController canSendMail]) {
     _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
     cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
     otherButtonTitles:NSLocalizedString(@"Save", nil), NSLocalizedString(@"Copy", nil), NSLocalizedString(@"Email", nil), nil];
     } else {
     _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
     cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
     otherButtonTitles:NSLocalizedString(@"Save", nil), NSLocalizedString(@"Copy", nil), nil];
     }
     _actionsSheet.tag = ACTION_SHEET_OLD_ACTIONS;
     _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
     if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
     [_actionsSheet showFromBarButtonItem:sender animated:YES];
     } else {
     [_actionsSheet showInView:self.view];
     }
     
     } else {
     
     // Show activity view controller
     NSMutableArray *items = [NSMutableArray arrayWithObject:[photo underlyingImage]];
     if (photo.caption) {
     [items addObject:photo.caption];
     }
     self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
     
     // Show loading spinner after a couple of seconds
     double delayInSeconds = 2.0;
     dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
     dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
     if (self.activityViewController) {
     [self showProgressHUDWithMessage:nil];
     }
     });
     
     // Show
     typeof(self) __weak weakSelf = self;
     [self.activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
     weakSelf.activityViewController = nil;
     [weakSelf hideControlsAfterDelay];
     [weakSelf hideProgressHUD:YES];
     }];
     [self presentViewController:self.activityViewController animated:YES completion:nil];
     
     }
     */
}

#pragma mark - MWPhotoBrowser Delegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    //NSLog(@"Did finish modal presentation");
    [_navigationController dismissViewControllerAnimated:YES completion:nil];
}




@end
