//
//  UTFinderTableViewController.m
//  utd
//
//  Created by 徐磊 on 14-6-29.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTFinderTableViewController.h"

#import "UTFinderEntity.h"
#import "MJRefresh.h"
//#import "UITabBarController+UTTabBarController.h"
#import "LGViewHUD.h"
#import "UTAlertViewDelegate.h"

@interface UTFinderTableViewController ()

@end

@implementation UTFinderTableViewController {
    UTFinderEntity *_currentEntity;
    UTActionIdentifier _action;
    NSString *_rawPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _myParentController.segment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kUTDefaultFinderStyle];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self.tableView registerClass:[SWTableViewCell class] forCellReuseIdentifier:@"FinderTableCell"];
    
    UIEdgeInsets defaultInsets = self.tableView.separatorInset;
    
    self.tableView.separatorInset = UIEdgeInsetsMake(defaultInsets.top, 15, defaultInsets.bottom, defaultInsets.right);
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self setLeftBarItem];
    
    [_myParentController layoutTitleViewForSegment:YES];
    
    [self addHeader];
    
    if (_myParentController.objects.count < 1) {
        [self refreshCurrentFolder];
    }
}

- (void)setLeftBarItem {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"go_up"] style:UIBarButtonItemStyleBordered target:self action:@selector(goUpperDirectory)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(addNewDirectory:)];
    }
}

- (void)hideToolBar {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setLeftBarItem];
    //[self.tabBarController showTabBarAnimated:NO];
    
    [_editingToolbar removeFromSuperview];
    [_myParentController layoutTitleViewForSegment:YES];
    
    _editingToolbar = nil;
    _myParentController.selectedItems = nil;
    _myParentController.selectedItemsFilePaths = nil;
}

- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    
    [self.tableView addHeaderWithCallback:^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
            [vc refreshCurrentFolder];
        } else {
            [vc goUpperDirectory];
        }
    }];
    
}

- (void)goUpperDirectory {
    
    if (_myParentController.isEditing) {
        [self setEditing:NO animated:YES];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (![[_myParentController.selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
            
            _myParentController.selectedItemPath = [_myParentController.selectedItemPath stringByDeletingLastPathComponent];
            
            [self refreshCurrentFolder];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView headerEndRefreshing];
            });
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView headerEndRefreshing];
                [_myParentController showHudWithMessage:NSLocalizedString(@"No More Upper Directories", nil) iconName:@"operation_failed"];
            });
        }
    });
}

- (void)refreshCurrentFolder {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block UIActivityIndicatorView *indicator;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [indicator setHidesWhenStopped:YES];
            [indicator startAnimating];
            
            self.navigationItem.leftBarButtonItem.customView = indicator;
            
        });
        
        _myParentController.objects = [[UTFinderEntity generateFilesInPath:_myParentController.selectedItemPath] mutableCopy];
        
        _myParentController.dirImages = [[NSMutableArray alloc] initWithCapacity:0];
        _myParentController.photos = [[NSMutableArray alloc] initWithCapacity:0];
        
        for (UTFinderEntity *entity in _myParentController.objects) {
            if (entity.type == UTFinderImageType) {
                [_myParentController.dirImages addObject:[UTFinderEntity imageWithFilePath:entity.filePath scaledToWidth:50.0f]];
            } else {
                [_myParentController.dirImages addObject:entity.typeImage];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.tableView.visibleCells.count > 30) {
                [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.tableView reloadData];
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
                [self.tableView headerEndRefreshing];
            }
            [indicator stopAnimating];
            indicator = nil;
            [self setLeftBarItem];
        });
    });
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingString:@"/Documents"];
    
    if ([_myParentController.selectedItemPath rangeOfString:path].location == NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Operating on application bundle file is prohibited.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [super setEditing:editing animated:animated];
    
    _myParentController.isEditing = editing;
    
    if (editing) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:_myParentController action:@selector(shareAction:)];
        
        [_myParentController layoutTitleViewForSegment:NO];
        
        //[self.tabBarController hideTabBarAnimated:YES];
        _editingToolbar = [[UIToolbar alloc] init];
        _editingToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        _editingToolbar.translucent = YES;
        _editingToolbar.barStyle = UIBarStyleDefault;
        _editingToolbar.alpha = 0.0f;
        [self.navigationController.view addSubview:_editingToolbar];
        
        [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _editingToolbar.alpha = 1.0f;
        } completion:nil];
        
        UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) style:UIBarButtonItemStyleBordered target:_myParentController action:@selector(deleteItems:)];
        deleteButtonItem.tintColor = [UIColor redColor];
        UIBarButtonItem *moveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Move", nil) style:UIBarButtonItemStyleBordered target:_myParentController action:@selector(moveItems:)];
        UIBarButtonItem *copyButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Copy", nil) style:UIBarButtonItemStyleBordered target:_myParentController action:@selector(copyItems:)];
        UIBarButtonItem *renameButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rename", nil) style:UIBarButtonItemStyleBordered target:_myParentController action:@selector(renameItems:)];
        
        _editingToolbar.items = @[deleteButtonItem,
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                  moveButtonItem,
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                  copyButtonItem,
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                  renameButtonItem];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_editingToolbar);
        [self.navigationController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_editingToolbar]|" options:kNilOptions metrics:nil views:views]];
        [self.navigationController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_editingToolbar(==44.0)]|" options:kNilOptions metrics:nil views:views]];
        
        _myParentController.selectedItems = [NSMutableArray array];
        _myParentController.selectedItemsFilePaths = [NSMutableArray array];
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
        
        _editingToolbar.delegate = _myParentController;
        
    } else {
        if (!_myParentController.lockForAction) {
            [self setLeftBarItem];
            //[self.tabBarController showTabBarAnimated:NO];
            [_editingToolbar removeFromSuperview];
            [_myParentController layoutTitleViewForSegment:YES];
            
            _editingToolbar = nil;
            _myParentController.selectedItems = nil;
            _myParentController.selectedItemsFilePaths = nil;
        } else {
            [self setLeftBarItem];
            
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(hideToolBar)];
        }
	}
    
}

- (void)updateTitleCount {
    NSUInteger count = [_myParentController.selectedItems count];
    
    if (count == 0) {
        self.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
    } else {
        if (count == 1) {
            self.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        } else {
            self.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Items Selected", nil), count];
        }
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:YES];
    }
}

- (void)updateEditStatus:(BOOL)isEdit {
    //NSLog(@"Called");
    _myParentController.isEditing = isEdit;
    
    [self refreshCurrentFolder];
    
    _myParentController.selectedItems = [NSMutableArray array];
}

#pragma mark - Table View

- (BOOL)pending {
#warning 判断是否能够选择row
    return !_myParentController.lockForAction;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _myParentController.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FinderTableCell" forIndexPath:indexPath];
    
    if (indexPath.row > _myParentController.objects.count) {
        return cell;
    }
    
    cell.delegate = self;
    
    UTFinderEntity *entity = _myParentController.objects[indexPath.row];
    
    cell.textLabel.text = entity.fileName;
    cell.detailTextLabel.text = entity.fileAttrs;
    
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.imageView.image = entity.typeImage;
    
    if (entity.type ==  UTFinderImageType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = _myParentController.dirImages[indexPath.row];
        });
    }
    
    cell.rightUtilityButtons = [self addRightButtons];
    
    cell.leftUtilityButtons = [self addLeftButtons];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.tableView.isEditing) {
        
        UTFinderFileType fileType = [(UTFinderEntity *)_myParentController.objects[indexPath.row] type];
        
        if (fileType == UTFinderFolderType) {
            
            _myParentController.selectedItemPath = [(UTFinderEntity *)_myParentController.objects[indexPath.row] filePath];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [self refreshCurrentFolder];
                
            });
        } else if (fileType == UTFinderImageType) {
            _myParentController.photos = [[NSMutableArray alloc] initWithCapacity:0];
            NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:0];
            
            NSString *curPath = [(UTFinderEntity *)_myParentController.objects[indexPath.row] filePath];
            
            for (UTFinderEntity *entity in _myParentController.objects) {
                if (entity.type == UTFinderImageType) {
                    [paths addObject:entity.filePath];
                    
                    MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:entity.filePath]];
                    photo.caption = [[entity.filePath componentsSeparatedByString:@"/"] lastObject];
                    
                    [_myParentController.photos addObject:photo];
                    
                }
            }
#warning iap图片浏览器
            [_myParentController showImageBrowserAtIndex:[paths indexOfObject:curPath]];
            
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        
        [_myParentController.selectedItems addObject:[NSNumber numberWithInteger:indexPath.row]];
        [_myParentController.selectedItemsFilePaths addObject:[[_myParentController.objects objectAtIndex:indexPath.row] filePath]];
        
        [self updateTitleCount];
    }

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        [_myParentController.selectedItems removeObject:[NSNumber numberWithInteger:indexPath.row]];
        [_myParentController.selectedItemsFilePaths removeObject:[[_myParentController.objects objectAtIndex:indexPath.row] filePath]];
        
        [self updateTitleCount];
    }
}

#pragma mark - SWTableViewCell

- (NSArray *)addLeftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:(float)246/255 green:(float)198/255 blue:(float)43/255 alpha:1.0f] title:NSLocalizedString(@"Share", nil)];
    
    return leftUtilityButtons;
}

- (NSArray *)addRightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:NSLocalizedString(@"More", nil)];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:NSLocalizedString(@"Delete", nil)];
   
    return rightUtilityButtons;
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    return YES;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    
    if (index == 0) {
        [cell hideUtilityButtonsAnimated:YES];
        _action = UTActionMore;
        
        NSUInteger index = [self.tableView indexPathForCell:cell].row;
        
        _currentEntity = [_myParentController.objects objectAtIndex:index];
        
        _rawPath = _currentEntity.filePath;
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        sheet.title = [NSString stringWithFormat:NSLocalizedString(@"What do you want to do with %@", nil), _currentEntity.fileName];
        sheet.actionSheetStyle = UIActionSheetStyleAutomatic;
        sheet.delegate = self;
        
        [sheet addButtonWithTitle:NSLocalizedString(@"Move", nil)];
        [sheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)];
        [sheet addButtonWithTitle:NSLocalizedString(@"Rename", nil)];
        [sheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
        [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        
        sheet.destructiveButtonIndex = 3;
        sheet.cancelButtonIndex = 4;
        
        [sheet showFromRect:CGRectMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height, 0, 0) inView:self.view animated:YES];
        
        //[sheet showFromTabBar:self.tabBarController.tabBar];
        
#warning More的index
    } else if (index == 1) {
        
        [cell hideUtilityButtonsAnimated:YES];
        _action = UTActionDelete;
        
        NSUInteger index = [self.tableView indexPathForCell:cell].row;
        
        _currentEntity = [_myParentController.objects objectAtIndex:index];
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        
        sheet.title = [NSString stringWithFormat:NSLocalizedString(@"Do you want to delete %@", nil), _currentEntity.fileName];
        sheet.delegate = self;
        sheet.actionSheetStyle = UIActionSheetStyleDefault;
        
        [sheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
        [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        
        sheet.cancelButtonIndex = 1;
        
        sheet.destructiveButtonIndex = 0;
        
        [sheet showFromRect:CGRectMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height, 0, 0) inView:self.view animated:YES];
        
        //[sheet showFromTabBar:self.tabBarController.tabBar];
        
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    if (index == 0) {
        [cell hideUtilityButtonsAnimated:YES];
        
        
        
        
        
        
    }
}

- (void)deleteSelectedFile:(id)sender {
    __block LGViewHUD *hud = [LGViewHUD defaultHUD];
    hud.bottomText = NSLocalizedString(@"Deleting Files", nil);
    [hud showInView:self.view];
    hud.activityIndicatorOn = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error;
        NSUInteger index;
        if (checkReachableAtPath(_currentEntity.filePath)) {
            [[NSFileManager defaultManager] removeItemAtPath:_currentEntity.filePath error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
            index = [_myParentController.objects indexOfObject:_currentEntity];
            [_myParentController.objects removeObject:_currentEntity];
        }
        
        _currentEntity = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [hud hideWithAnimation:HUDAnimationNone];
            
            hud = nil;
            [self showHudWithMessage:NSLocalizedString(@"Deleted", nil) iconName:@"operation_done"];
        });
    });

}

- (void)operateFile:(id)sender {
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_myParentController action:@selector(addNewDirectory:)];
    
    [_myParentController layoutTitleViewForSegment:NO];
    _myParentController.textLabel.text = NSLocalizedString(@"Choose Destination", nil);
    self.navigationItem.rightBarButtonItem = nil;
    //[self.tabBarController hideTabBarAnimated:YES];
    _editingToolbar = [[UIToolbar alloc] init];
    _editingToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    _editingToolbar.translucent = YES;
    _editingToolbar.barStyle = UIBarStyleDefault;
    [self.navigationController.view addSubview:_editingToolbar];
    
    UIBarButtonItem *actionButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Put", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(destinationDidSelected:)];
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelAction:)];
    
    _editingToolbar.items = @[cancelButtonItem,
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                              actionButtonItem];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_editingToolbar);
    [self.navigationController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_editingToolbar]|" options:kNilOptions metrics:nil views:views]];
    [self.navigationController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_editingToolbar(==44.0)]|" options:kNilOptions metrics:nil views:views]];
}

- (void)renameFile:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.message = NSLocalizedString(@"Please Input New Name", nil);
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alertView addButtonWithTitle:NSLocalizedString(@"Rename", nil)];
    alertView.cancelButtonIndex = 0;
    
    [UTAlertViewDelegate showAlertView:alertView withCallback:^(NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSError *error;
            NSString *newName = [alertView textFieldAtIndex:0].text;
            NSString *newPath = [[_currentEntity.filePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", newName];
            [[NSFileManager defaultManager] moveItemAtPath:_currentEntity.filePath toPath:newPath error:&error];
            
            if (!error) {
                _currentEntity.fileName = newName;
                _currentEntity.filePath = newPath;
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[_myParentController.objects indexOfObject:_currentEntity] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                _currentEntity = nil;
            }
        }
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_action == UTActionDelete && buttonIndex == actionSheet.destructiveButtonIndex) {
        
        [self deleteSelectedFile:actionSheet];
        
    } else if (buttonIndex != actionSheet.cancelButtonIndex) {
        switch (buttonIndex) {
            case 0:
                _action = UTActionMove;
                [self operateFile:actionSheet];
                break;
                
            case 1:
                _action = UTActionCopy;
                [self operateFile:actionSheet];
                break;
                
            case 2:
                _action = UTActionRename;
                [self renameFile:actionSheet];
                break;
                
            case 3: {
                
                _action = UTActionDelete;
                
                UIActionSheet *sheet = [[UIActionSheet alloc] init];
                
                sheet.title = [NSString stringWithFormat:NSLocalizedString(@"Do you want to delete %@", nil), _currentEntity.fileName];
                sheet.delegate = self;
                sheet.actionSheetStyle = UIActionSheetStyleDefault;
                
                [sheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
                [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                
                sheet.cancelButtonIndex = 1;
                
                sheet.destructiveButtonIndex = 0;
                
                [sheet showFromRect:CGRectMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height, 0, 0) inView:self.view animated:YES];
                
                //[sheet showFromTabBar:self.tabBarController.tabBar];
                
                break;
            }
            default:
                break;
        }
        
    }
}

- (void)destinationDidSelected:(id)sender {
    
    [_myParentController.selectedItems addObject:[NSNumber numberWithInteger:[_myParentController.objects indexOfObject:_currentEntity]]];
    [_myParentController.selectedItemsFilePaths addObject:_currentEntity.filePath];
    
    if (_currentEntity.type == UTFinderImageType) {
        [_myParentController.dirImages addObject:[UTFinderEntity imageWithFilePath:_currentEntity.filePath scaledToWidth:50.0f]];
    } else {
        [_myParentController.dirImages addObject:_currentEntity.typeImage];
    }
    
    _myParentController.action = _action;
    [_myParentController operateItems:sender action:_action];
}

- (void)cancelAction:(id)sender {
    [self hideToolBar];
    
    _myParentController.selectedItemPath = [_rawPath stringByDeletingLastPathComponent];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self refreshCurrentFolder];
        
    });
    
}

- (void)showHudWithMessage:(NSString *)message iconName:(NSString *)name {
   LGViewHUD *hud = [LGViewHUD defaultHUD];
   hud.bottomText = message;
   [hud showInView:self.view withAnimation:HUDAnimationNone];
   
   if (name) {
       hud.image = [UIImage imageNamed:name];
   }
   
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
       [hud hideWithAnimation:HUDAnimationHideFadeOut];
   });
   
}

@end

