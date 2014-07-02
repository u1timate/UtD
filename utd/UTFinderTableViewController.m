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
#import "UITabBarController+UTTabBarController.h"
#import "LGViewHUD.h"

@interface UTFinderTableViewController ()

@end

@implementation UTFinderTableViewController {
    UTFinderEntity *_currentEntity;
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
    
    [self refreshCurrentFolder];
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
    [self.tabBarController showTabBarAnimated:NO];
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
            
            [self.tabBarController hideTabBarAnimated:YES];
            _editingToolbar = [[UIToolbar alloc] init];
            _editingToolbar.translatesAutoresizingMaskIntoConstraints = NO;
            _editingToolbar.translucent = YES;
            _editingToolbar.barStyle = UIBarStyleDefault;
            [self.tabBarController.view addSubview:_editingToolbar];
            
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
            [self.tabBarController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_editingToolbar]|" options:kNilOptions metrics:nil views:views]];
            [self.tabBarController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_editingToolbar(==44.0)]|" options:kNilOptions metrics:nil views:views]];
            
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
            [self.tabBarController showTabBarAnimated:NO];
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
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                _myParentController.selectedItemPath = [(UTFinderEntity *)_myParentController.objects[indexPath.row] filePath];
                
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
        
#warning More的index
    } else if (index == 1) {
        
        [cell hideUtilityButtonsAnimated:YES];
        
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
        
        [sheet showFromTabBar:self.tabBarController.tabBar];
        
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    if (index == 0) {
        [cell hideUtilityButtonsAnimated:YES];
        
        
        
        
        
        
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
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

