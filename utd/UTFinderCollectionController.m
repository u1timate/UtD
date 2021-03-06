//
//  UTFinderCollectionController.m
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTFinderCollectionController.h"

#import "UTFinderEntity.h"

#import "UTCollectionViewCell.h"

#import "MJRefresh.h"

#import "UITabBarController+UTTabBarController.h"

#import "UTAlertViewDelegate.h"

#import "LGViewHUD.h"

@interface UTFinderCollectionController ()

@property (strong, nonatomic) UISegmentedControl *segment;

@property (strong, nonatomic) UILabel *textLabel;

@property (strong, nonatomic) UIToolbar *editingToolbar;

@property (weak, nonatomic) UIActivityViewController *activityViewController;

@property (assign, nonatomic) BOOL lockForAction;

@end

typedef enum {
    UTActionDelete = 0,
    UTActionCopy = 1,
    UTActionMove = 2,
    UTActionRename = 3
} UTActionIdentifier;

#define PADDING                  10
#define ACTION_SHEET_OLD_ACTIONS 2000

@implementation UTFinderCollectionController {
    NSMutableArray *_objects;
    NSMutableArray *_photos;
    NSMutableArray *_dirImages;
    NSMutableArray *_selectedItems;
    NSMutableArray *_selectedItemsFilePaths;
    NSString *_selectedItemPath;
    NSString *_documentPath;
    UTFinderStyle _currentFinderStyle;
    UTActionIdentifier _action;
    BOOL _isEditing;
}

- (void)viewDidLoad {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentPath = [paths firstObject];
    
#warning 测试文件操作用的。正式版需要删除
    [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Checkmark.png"] toPath:[_documentPath stringByAppendingString:@"/Checkmark.png"] error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/RefreshArrow.png"] toPath:[_documentPath stringByAppendingString:@"/RefreshArrow.png"] error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Up.png"] toPath:[_documentPath stringByAppendingString:@"/Up.png"] error:nil];
    
    _lockForAction = NO;
    
    self.collectionView.alwaysBounceVertical = YES;
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] init];
    barButton.title = NSLocalizedString(@"Edit", nil);
    barButton.target = self;
    barButton.action = @selector(setFinderEditing:);
    self.navigationItem.rightBarButtonItem = barButton;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewDirectory:)];
    
    [self layoutTitleViewForSegment:YES];
    
    [self addHeader];
    
    _dirImages = [NSMutableArray array];
    _objects = [NSMutableArray array];
    _photos = [NSMutableArray array];
    _selectedItems = [NSMutableArray array];
    _selectedItemsFilePaths = [NSMutableArray array];
    
    _currentFinderStyle = UTFinderLayoutTableStyle;
    
    switch (_currentFinderStyle) {
        case UTFinderLayoutCollectionStyle:
            [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCollectionCell"];
            break;
            
        default:
            [self.collectionView registerClass:[UTTableViewCell class] forCellWithReuseIdentifier:@"FinderTableCell"];
            break;
    }
    
        
    _selectedItemPath = _documentPath;
        
    [self refreshCurrentFolder];
}

- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    
    [self.collectionView addHeaderWithCallback:^{
        [vc goUpperDirectory];
    }];
}

- (void)goUpperDirectory {
    
    if (_isEditing) {
        [self setFinderEditing:nil];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (![[_selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
            
            _selectedItemPath = [_selectedItemPath stringByDeletingLastPathComponent];
            
            [self refreshCurrentFolder];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
                [self.collectionView headerEndRefreshing];
            });
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView headerEndRefreshing];
                [self showHudWithMessage:NSLocalizedString(@"No More Upper Directories", nil) iconName:@"operation_failed"];
            });
        }
    });
}

#pragma mark - IBAction

- (void)layoutTitleViewForSegment:(BOOL)seg {
    if (seg) {
        
        _textLabel = nil;
        
        NSArray *itemArray = @[NSLocalizedString(@"Table", nil), NSLocalizedString(@"Collection", nil)];
        _segment = [[UISegmentedControl alloc] initWithItems:itemArray];
        _segment.frame = CGRectMake(0, 0, 150, 30);
        _segment.segmentedControlStyle = UISegmentedControlStylePlain;
        self.navigationItem.titleView = _segment;
        
        [_segment addTarget:self action:@selector(changeStyle:) forControlEvents: UIControlEventValueChanged];
        _segment.selectedSegmentIndex = 0;
        
    } else {
        
        _segment = nil;
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
        
        self.navigationItem.titleView = _textLabel;
        
        NSUInteger count = 0;
        
        _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        
        
    }
    
}

- (void)changeStyle:(id)sender {
    _currentFinderStyle = (UTFinderStyle)[sender selectedSegmentIndex];
    switch (_currentFinderStyle) {
        case UTFinderLayoutCollectionStyle:
            [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCollectionCell"];
            break;
            
        default:
            [self.collectionView registerClass:[UTTableViewCell class] forCellWithReuseIdentifier:@"FinderTableCell"];
            break;
    }
    
    [self.collectionView performBatchUpdates:^{
        UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
        layout = [self myCollectionViewLayout];
    } completion:^(BOOL finished) {
        if (finished) {
            [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        }
    }];
}

#pragma mark - Collection View

- (void)setFinderEditing:(id)sender {
    
    NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingString:@"/Documents"];
    
    if ([_selectedItemPath rangeOfString:path].location == NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Operating on application bundle file is prohibited.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    if ([[sender title] isEqualToString:NSLocalizedString(@"Edit", nil)]) {
        _isEditing = YES;
    } else {
        _isEditing = NO;
    }
    
	if (_isEditing) {
        
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Cancel", nil);
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction:)];
        
        [self layoutTitleViewForSegment:NO];
        
		[self.tabBarController hideTabBarAnimated:NO];
		_editingToolbar = [[UIToolbar alloc] init];
		_editingToolbar.translatesAutoresizingMaskIntoConstraints = NO;
		_editingToolbar.translucent = YES;
        _editingToolbar.barStyle = UIBarStyleDefault;
		[self.tabBarController.view addSubview:_editingToolbar];
        
        UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(deleteItems:)];
        deleteButtonItem.tintColor = [UIColor redColor];
        UIBarButtonItem *moveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Move", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(moveItems:)];
        UIBarButtonItem *copyButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Copy", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(copyItems:)];
        UIBarButtonItem *renameButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rename", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(renameItems:)];
        
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
        
		_selectedItems = [NSMutableArray array];
        _selectedItemsFilePaths = [NSMutableArray array];
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
        
		_editingToolbar.delegate = self;
        
	} else {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", nil);
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewDirectory:)];
        [self.tabBarController showTabBarAnimated:NO];
        [_editingToolbar removeFromSuperview];
        [self layoutTitleViewForSegment:YES];
        
        _editingToolbar = nil;
        _selectedItems = nil;
        _selectedItemsFilePaths = nil;
	}
    
    [self updateEditStatus:_isEditing];
    [self layoutTitleViewForSegment:!_isEditing];
}

- (UICollectionViewLayout *)myCollectionViewLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
 
    switch (_currentFinderStyle) {
        case UTFinderLayoutCollectionStyle:
            flowLayout.itemSize = CGSizeMake(80, 100);
            break;
            
        default:
            flowLayout.itemSize = CGSizeMake(320, 60);
            break;
    }
 
    return flowLayout;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return !_lockForAction;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return _currentFinderStyle == UTFinderLayoutTableStyle ? CGSizeMake(320, 60) : CGSizeMake(80, 100);
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _objects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
        UTCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FinderCollectionCell" forIndexPath:indexPath];
        
        UTFinderEntity *entity = _objects[indexPath.row];
        
        cell.textField.text = entity.fileName;
        
        cell.imageView.image = entity.typeImage;
        
        if (entity.type ==  UTFinderImageType) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = _dirImages[indexPath.row];
            });
        }
        
        if (_isEditing) {
            
            if (!cell.button) {
                cell.button = [UIButton buttonWithType:UIButtonTypeCustom];
                [cell.button setImage:[UIImage imageNamed:@"select"] forState:UIControlStateNormal];
                [cell.button setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateSelected];
                [cell.button sizeToFit];
                cell.button.adjustsImageWhenHighlighted = NO;
                
                cell.button.frame = CGRectMake(0, 0, 44, 44);
                float x = cell.imageView.center.y;
                cell.button.center = CGPointMake(x, x);
                
                [cell.button addTarget:self action:@selector(selectedButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
                
                [cell addSubview:cell.button];
            }
            
            if ([_selectedItems containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
                cell.button.selected = YES;
            } else {
                cell.button.selected = NO;
            }
            
        } else {
            [cell.button removeFromSuperview];
            cell.button = nil;
        }
        
        return cell;
        
    } else {
        UTTableViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FinderTableCell" forIndexPath:indexPath];
        
        UTFinderEntity *entity = _objects[indexPath.row];
        
        cell.textField.text = entity.fileName;

        cell.detailTextField.text = entity.fileAttrs;
        
        cell.imageView.image = entity.typeImage;
        
        if (entity.type ==  UTFinderImageType) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = _dirImages[indexPath.row];
                //cell.imageView.image = [UTFinderEntity thumbForImageAtPath:entity.filePath destinationSize:CGSizeMake(50, 50)];
            });
        }
        
        if (_isEditing) {
            
            if (!cell.button) {
                cell.button = [UIButton buttonWithType:UIButtonTypeCustom];
                [cell.button setImage:[UIImage imageNamed:@"select"] forState:UIControlStateNormal];
                [cell.button setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateSelected];
                [cell.button sizeToFit];
                cell.button.adjustsImageWhenHighlighted = NO;
                
                cell.button.frame = CGRectMake(0, 0, 44, 44);
                float y = cell.imageView.center.y;
                cell.button.center = CGPointMake(320 - 25, y);
                
                [cell.button addTarget:self action:@selector(selectedButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
                
                [cell addSubview:cell.button];
            }
            
            if ([_selectedItems containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
                cell.button.selected = YES;
            } else {
                cell.button.selected = NO;
            }
            
        } else {
            [cell.button removeFromSuperview];
            cell.button = nil;
        }
        
        return cell;
    }
}

- (void)selectedButtonTapped:(id)sender event:(id)event {
    [sender setSelected:![sender isSelected]];
    
    NSSet *touches = [event allTouches];
    
    UITouch *touch = [touches anyObject];
    
    CGPoint currentTouchPosition = [touch locationInView:self.collectionView];
    
    NSUInteger index = [[self.collectionView indexPathForItemAtPoint:currentTouchPosition] row];
    
    if ([sender isSelected]) {
        [_selectedItems addObject:[NSNumber numberWithInteger:index]];
        [_selectedItemsFilePaths addObject:[[_objects objectAtIndex:index] filePath]];
    } else {
        [_selectedItems removeObject:[NSNumber numberWithInteger:index]];
        [_selectedItemsFilePaths removeObject:[[_objects objectAtIndex:index] filePath]];
    }
    
    NSUInteger count = [_selectedItems count];
    
    if (count == 0) {
        _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
    } else {
        if (count == 1) {
            _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        } else {
            _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Items Selected", nil), count];
        }
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:YES];
        
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!_isEditing) {
        UTFinderFileType fileType = [(UTFinderEntity *)_objects[indexPath.row] type];
        
        if (fileType == UTFinderFolderType) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                _selectedItemPath = [(UTFinderEntity *)_objects[indexPath.row] filePath];
                
                [self refreshCurrentFolder];
                
            });
        } else if (fileType == UTFinderImageType) {
            _photos = [[NSMutableArray alloc] initWithCapacity:0];
            NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:0];
            
            NSString *curPath = [(UTFinderEntity *)_objects[indexPath.row] filePath];
            
            for (UTFinderEntity *entity in _objects) {
                if (entity.type == UTFinderImageType) {
                    [paths addObject:entity.filePath];
                    
                    MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:entity.filePath]];
                    photo.caption = [[entity.filePath componentsSeparatedByString:@"/"] lastObject];
                    
                    [_photos addObject:photo];
                    
                }
            }
            
            [self showImageBrowserAtIndex:[paths indexOfObject:curPath]];
            
        }
    } else {
        UTCollectionViewCell *cell = (UTCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.button.selected = !cell.button.selected;
        if ([cell.button isSelected]) {
            [_selectedItems addObject:[NSNumber numberWithInteger:indexPath.row]];
            [_selectedItemsFilePaths addObject:[[_objects objectAtIndex:indexPath.row] filePath]];
        } else {
            [_selectedItems removeObject:[NSNumber numberWithInteger:indexPath.row]];
            [_selectedItemsFilePaths removeObject:[[_objects objectAtIndex:indexPath.row] filePath]];
        }
        
        NSUInteger count = [_selectedItems count];
		if (count == 0) {
            _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
            [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
            [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
            [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
            [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
        } else {
            if (count == 1) {
                _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
            } else {
                _textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Items Selected", nil), count];
            }
            [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:YES];
            [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:YES];
            [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:YES];
            [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:YES];
            
        }
        
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
    self.navigationItem.leftBarButtonItem.enabled = !locked;
    self.navigationItem.rightBarButtonItem.enabled = !locked;
    self.segment.enabled = !locked;
    for (UIBarButtonItem *item in _editingToolbar.items) {
        item.enabled = !locked;
    }
}

- (void)refreshCurrentFolder {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _objects = [[UTFinderEntity generateFilesInPath:_selectedItemPath] mutableCopy];
        
        for (UTFinderEntity *entity in _objects) {
            if (entity.type == UTFinderImageType) {
                [_dirImages addObject:[UTFinderEntity imageWithFilePath:entity.filePath scaledToWidth:70.0f]];
            } else {
                [_dirImages addObject:entity.typeImage];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.collectionView.visibleCells.count > 30) {
                [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
            } else {
                [self.collectionView reloadData];
            }
        });
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

#pragma mark Toolbar Edit

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
                entity.fileName = dirname;
                entity.filePath = [_documentPath stringByAppendingFormat:@"/%@", dirname];
#warning 新建文件夹属性？
                entity.fileAttrs = @"Some Attributes";
                [_objects addObject:entity];
                
                [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.collectionView.visibleCells.count inSection:0]]];
            }
        }];
    }
}

- (void)updateEditStatus:(BOOL)isEdit {
    //NSLog(@"Called");
    _isEditing = isEdit;
    
    [self refreshCurrentFolder];
    
    _selectedItems = [NSMutableArray array];
}

- (void)deleteItems:(id)sender {
    
    _action = UTActionDelete;
    
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
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
    
    [sheet showFromToolbar:_editingToolbar];
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
    
    if (![[sender title] isEqualToString:NSLocalizedString(@"Put", nil)]) {
        [sender setTitle:NSLocalizedString(@"Put", nil)];
        _textLabel.text = NSLocalizedString(@"Choose Destination", nil);
        
        _isEditing = NO;
        
        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        
        switch (action) {
            case UTActionMove:
                [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
                [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
                [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
                break;
                
            case UTActionCopy:
                [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
                [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
                [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
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
        
        [sheet showFromToolbar:_editingToolbar];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        self.lockForAction = YES;
        __block NSError *error;
        switch (_action) {
            case UTActionDelete: {
                
                __block LGViewHUD *hud = [LGViewHUD defaultHUD];
                hud.bottomText = NSLocalizedString(@"Deleting Files", nil);
                [hud showInView:self.view];
                hud.activityIndicatorOn = YES;
                
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
                                break;
                            }
                            [_objects removeObject:entity];
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.collectionView deleteItemsAtIndexPaths:indexpaths];
                        [self setFinderEditing:nil];
                        [hud hideWithAnimation:HUDAnimationNone];
                        [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
                        hud = nil;
                        [self showHudWithMessage:NSLocalizedString(@"Deleted", nil) iconName:@"operation_done"];
                    });
                    
                });
                break;
            }
                
            case UTActionMove: {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    __block LGViewHUD *hud = [LGViewHUD defaultHUD];
                    hud.bottomText = NSLocalizedString(@"Moving Files", nil);
                    [hud showInView:self.view];
                    hud.activityIndicatorOn = YES;
                    
                    for (NSString *filePath in _selectedItemsFilePaths) {
                        NSString *fileName = [[filePath componentsSeparatedByString:@"/"] lastObject];
                        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[_selectedItemPath stringByAppendingFormat:@"/%@", fileName] error:&error];
                        if (error) {
                            NSLog(@"%@", error);
                            break;
                        }
                        
                        UTFinderEntity *entity = [[UTFinderEntity alloc] init];
                        entity.fileName = fileName;
                        entity.filePath = [_selectedItemPath stringByAppendingFormat:@"/%@", fileName];
#warning 移动的文件属性
                        entity.fileAttrs = @"Some Attributes";
                        
                        [_objects addObject:entity];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.collectionView.visibleCells.count inSection:0]]];
                        });
                        
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self setFinderEditing:nil];
                        [hud hideWithAnimation:HUDAnimationNone];
                        hud = nil;
                        [self showHudWithMessage:NSLocalizedString(@"Moved", nil) iconName:@"operation_done"];
                    });
                });
                break;
            }
                
            case UTActionCopy: {
                
                __block LGViewHUD *hud = [LGViewHUD defaultHUD];
                hud.bottomText = NSLocalizedString(@"Copying Files", nil);
                [hud showInView:self.view];
                hud.activityIndicatorOn = YES;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    for (NSString *filePath in _selectedItemsFilePaths) {
                        NSString *fileName = [[filePath componentsSeparatedByString:@"/"] lastObject];
                        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:[_selectedItemPath stringByAppendingFormat:@"/%@", fileName] error:&error];
                        if (error) {
                            NSLog(@"%@", error);
                            break;
                        }
                        
                        UTFinderEntity *entity = [[UTFinderEntity alloc] init];
                        entity.fileName = fileName;
                        entity.filePath = [_selectedItemPath stringByAppendingFormat:@"/%@", fileName];
#warning 复制的文件属性
                        entity.fileAttrs = @"Some Attributes";
                        
                        [_objects addObject:entity];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.collectionView.visibleCells.count inSection:0]]];
                        });
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setFinderEditing:nil];
                        [hud hideWithAnimation:HUDAnimationNone];
                        hud = nil;
                        [self showHudWithMessage:NSLocalizedString(@"Copied", nil) iconName:@"operation_done"];
                    });
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
        self.lockForAction = NO;
    }
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
                    entity.fileName = newDir;
#warning 获取新文件的属性
                    entity.fileAttrs = @"Some New Attrs";
                    
                    if (error) {
                        NSLog(@"%@", error);
                        break;
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
                    entity.fileName = newDir;
#warning 获取新文件的属性
                    entity.fileAttrs = @"Some New Attributes";
                    
                    if (error) {
                        NSLog(@"%@", error);
                        break;
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
            
            
            
            [self setFinderEditing:nil];
            
            [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
            
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
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)shareAction:(id)sender {
    NSLog(@"Not done");
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
