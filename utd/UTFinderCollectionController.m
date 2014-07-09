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


#define PADDING                  10
#define ACTION_SHEET_OLD_ACTIONS 2000

@implementation UTFinderCollectionController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] init];
    barButton.title = NSLocalizedString(@"Edit", nil);
    barButton.target = self;
    barButton.action = @selector(setFinderEditing:);
    self.navigationItem.rightBarButtonItem = barButton;
    
    [self setLeftBarItem];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    self.collectionView.alwaysBounceVertical = YES;
    
    [_myParentController layoutTitleViewForSegment:YES];
    
    _myParentController.segment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kUTDefaultFinderStyle];
    
    [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCollectionCell"];
    
    [self addHeader];
    
    if (_myParentController.objects.count < 1) {
        [self refreshCurrentFolder];
    }
}

- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    
    [self.collectionView addHeaderWithCallback:^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
            [vc refreshCurrentFolder];
        } else {
            [vc goUpperDirectory];
        }
    }];
}

- (void)setLeftBarItem {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"go_up"] style:UIBarButtonItemStyleBordered target:self action:@selector(goUpperDirectory)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(addNewDirectory:)];
    }
}

- (void)goUpperDirectory {
    
    if (_myParentController.isEditing) {
        [self setFinderEditing:nil];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (![[_myParentController.selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
            
            _myParentController.selectedItemPath = [_myParentController.selectedItemPath stringByDeletingLastPathComponent];
            
            [self refreshCurrentFolder];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView headerEndRefreshing];
            });
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView headerEndRefreshing];
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
                [_myParentController.dirImages addObject:[UTFinderEntity imageWithFilePath:entity.filePath scaledToWidth:70.0f]];
            } else {
                [_myParentController.dirImages addObject:entity.typeImage];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.collectionView.visibleCells.count > 30) {
                [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
            } else {
                [self.collectionView reloadData];
            }
            
            [indicator stopAnimating];
            indicator = nil;
            
            [self.collectionView headerEndRefreshing];
            [self setLeftBarItem];
        });
    });
}

- (void)updateEditStatus:(BOOL)isEdit {
    //NSLog(@"Called");
    _myParentController.isEditing = isEdit;
    
    [self refreshCurrentFolder];
    
    _myParentController.selectedItems = [NSMutableArray array];
}

#pragma mark - Collection View

- (void)setFinderEditing:(id)sender {
    
    NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingString:@"/Documents"];
    
    if ([_myParentController.selectedItemPath rangeOfString:path].location == NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Operating on application bundle file is prohibited.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    if ([[sender title] isEqualToString:NSLocalizedString(@"Edit", nil)]) {
        _myParentController.isEditing = YES;
    } else {
        _myParentController.isEditing = NO;
    }
    
	if (_myParentController.isEditing) {
        
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Cancel", nil);
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:_myParentController action:@selector(shareAction:)];
        
        [_myParentController layoutTitleViewForSegment:NO];
        
		//[self.tabBarController hideTabBarAnimated:NO];
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
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", nil);
        
        [self setLeftBarItem];
        
        //[self.tabBarController showTabBarAnimated:NO];
        [_editingToolbar removeFromSuperview];
        [_myParentController layoutTitleViewForSegment:YES];
        
        _editingToolbar = nil;
        _myParentController.selectedItems = nil;
        _myParentController.selectedItemsFilePaths = nil;
	}
    [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
    [_myParentController layoutTitleViewForSegment:!_myParentController.isEditing];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return !_myParentController.lockForAction;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(80, 100);
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _myParentController.objects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UTCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FinderCollectionCell" forIndexPath:indexPath];
    
    if (indexPath.row > _myParentController.objects.count) {
        return cell;
    }
    
    UTFinderEntity *entity = _myParentController.objects[indexPath.row];
    
    if (entity.fileName.length > 6) {
        cell.textField.text = [[entity.fileName substringToIndex:6] stringByAppendingString:@".."];
    } else {
        cell.textField.text = entity.fileName;
    }
    
    
    
    cell.imageView.image = entity.typeImage;
    
    if (entity.type ==  UTFinderImageType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = _myParentController.dirImages[indexPath.row];
        });
    }
    
    if (_myParentController.isEditing) {
        
        if (!cell.button) {
            cell.button = [UIButton buttonWithType:UIButtonTypeCustom];
            [cell.button setImage:[UIImage imageNamed:@"select"] forState:UIControlStateNormal];
            [cell.button setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateSelected];
            [cell.button sizeToFit];
            cell.button.adjustsImageWhenHighlighted = NO;
            
            cell.button.frame = CGRectMake(0, 0, 44, 44);
            cell.button.center = CGPointMake(62, 64);
            
            [cell.button addTarget:self action:@selector(selectedButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            
            [cell addSubview:cell.button];
        }
        
        if ([_myParentController.selectedItems containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            cell.button.selected = YES;
            cell.backgroundColor = [UIColor colorWithRed:(float)232/255 green:(float)240/255 blue:(float)250/255 alpha:1.0f];
        } else {
            cell.button.selected = NO;
            cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
        }
        
    } else {
        [cell.button removeFromSuperview];
        cell.button = nil;
    }
    
    return cell;
}

- (void)selectedButtonTapped:(id)sender event:(id)event {
    [sender setSelected:![sender isSelected]];
    
    NSSet *touches = [event allTouches];
    
    UITouch *touch = [touches anyObject];
    
    CGPoint currentTouchPosition = [touch locationInView:self.collectionView];
    
    NSUInteger index = [[self.collectionView indexPathForItemAtPoint:currentTouchPosition] row];
    
    UTCollectionViewCell *cell = (UTCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    
    
    if ([sender isSelected]) {
        [_myParentController.selectedItems addObject:[NSNumber numberWithInteger:index]];
        [_myParentController.selectedItemsFilePaths addObject:[[_myParentController.objects objectAtIndex:index] filePath]];
        cell.backgroundColor = [UIColor colorWithRed:(float)232/255 green:(float)240/255 blue:(float)250/255 alpha:1.0f];
    } else {
        [_myParentController.selectedItems removeObject:[NSNumber numberWithInteger:index]];
        [_myParentController.selectedItemsFilePaths removeObject:[[_myParentController.objects objectAtIndex:index] filePath]];
        cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
    }
    
    NSUInteger count = [_myParentController.selectedItems count];
    
    if (count == 0) {
        _myParentController.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
    } else {
        if (count == 1) {
            _myParentController.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
        } else {
            _myParentController.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Items Selected", nil), count];
        }
        [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:YES];
        [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:YES];
        
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!_myParentController.isEditing) {
        
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
            
            [_myParentController showImageBrowserAtIndex:[paths indexOfObject:curPath]];
            
        }
    } else {
        UTCollectionViewCell *cell = (UTCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.button.selected = !cell.button.selected;
        if ([cell.button isSelected]) {
            [_myParentController.selectedItems addObject:[NSNumber numberWithInteger:indexPath.row]];
            [_myParentController.selectedItemsFilePaths addObject:[[_myParentController.objects objectAtIndex:indexPath.row] filePath]];
            cell.backgroundColor = [UIColor colorWithRed:(float)232/255 green:(float)240/255 blue:(float)250/255 alpha:1.0f];
        } else {
            [_myParentController.selectedItems removeObject:[NSNumber numberWithInteger:indexPath.row]];
            [_myParentController.selectedItemsFilePaths removeObject:[[_myParentController.objects objectAtIndex:indexPath.row] filePath]];
            cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
        }
        
        NSUInteger count = [_myParentController.selectedItems count];
		if (count == 0) {
            _myParentController.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
            [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:NO];
            [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:NO];
            [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:NO];
            [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:NO];
        } else {
            if (count == 1) {
                _myParentController.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Item Selected", nil), count];
            } else {
                _myParentController.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Items Selected", nil), count];
            }
            [(UIBarButtonItem *)_editingToolbar.items[0] setEnabled:YES];
            [(UIBarButtonItem *)_editingToolbar.items[2] setEnabled:YES];
            [(UIBarButtonItem *)_editingToolbar.items[4] setEnabled:YES];
            [(UIBarButtonItem *)_editingToolbar.items[6] setEnabled:YES];
            
        }
        
    }
    
}

@end
