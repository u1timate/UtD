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

@interface UTFinderTableViewController ()

@end

@implementation UTFinderTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _myParentController.segment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kUTDefaultFinderStyle];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self.tableView registerClass:[UTTableViewCell class] forCellReuseIdentifier:@"FinderTableCell"];
    
    UIEdgeInsets defaultInsets = self.tableView.separatorInset;
    
    self.tableView.separatorInset = UIEdgeInsetsMake(defaultInsets.top, 15, defaultInsets.bottom, defaultInsets.right);
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewDirectory:)];
    [_myParentController layoutTitleViewForSegment:YES];
    
    [self addHeader];
    
    [self refreshCurrentFolder];
}

- (void)hideToolBar {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewDirectory:)];
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
        [vc goUpperDirectory];
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
            
            [indicator stopAnimating];
            indicator = nil;
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_myParentController action:@selector(addNewDirectory:)];
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
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_myParentController action:@selector(addNewDirectory:)];
            [self.tabBarController showTabBarAnimated:NO];
            [_editingToolbar removeFromSuperview];
            [_myParentController layoutTitleViewForSegment:YES];
            
            _editingToolbar = nil;
            _myParentController.selectedItems = nil;
            _myParentController.selectedItemsFilePaths = nil;
        } else {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewDirectory:)];
            
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
    
    UTTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FinderTableCell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UTTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FinderTableCell"];
    }
    
    if (indexPath.row > _myParentController.objects.count) {
        return cell;
    }
    
    
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

@end



@implementation UTTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}



- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.imageView.frame;
    
    self.imageView.frame = CGRectMake(frame.origin.x + 5, frame.origin.y + 5, 45, 45);
    
    frame = self.textLabel.frame;
    
    self.textLabel.frame = CGRectMake(self.imageView.frame.origin.x + self.imageView.frame.size.width + 15, frame.origin.y, frame.size.width, frame.size.height);
    
    frame = self.detailTextLabel.frame;
    
    self.detailTextLabel.frame = CGRectMake(self.imageView.frame.origin.x + self.imageView.frame.size.width + 15, frame.origin.y, frame.size.width, frame.size.height);
}

@end
