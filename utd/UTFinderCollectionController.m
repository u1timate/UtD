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


@implementation UTFinderCollectionController {
    NSMutableArray *_objects;
    NSMutableArray *_photos;
    NSString *_selectedItemPath;
    UTFinderStyle _currentFinderStyle;
}

- (void)viewDidLoad {
    
    
    self.collectionView.alwaysBounceVertical = YES;
    
    [self addHeader];
    
    _currentFinderStyle = UTFinderLayoutTableStyle;
    
    switch (_currentFinderStyle) {
        case UTFinderLayoutCollectionStyle:
            [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCollectionCell"];
            break;
            
        default:
            [self.collectionView registerClass:[UTTableViewCell class] forCellWithReuseIdentifier:@"FinderTableCell"];
            break;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        _selectedItemPath = [[NSBundle mainBundle] resourcePath];
        
        _objects = [[UTFinderEntity generateFilesInPath:_selectedItemPath] mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
}

- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    
    [self.collectionView addHeaderWithCallback:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [vc.collectionView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [vc.collectionView headerEndRefreshing];
                
            });
        });
    }];
}

#pragma mark - IBAction

- (IBAction)changeStyle:(id)sender {
    _currentFinderStyle = [sender selectedSegmentIndex];
    switch (_currentFinderStyle) {
        case UTFinderLayoutCollectionStyle:
            [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCollectionCell"];
            break;
            
        default:
            [self.collectionView registerClass:[UTTableViewCell class] forCellWithReuseIdentifier:@"FinderTableCell"];
            break;
    }
    [self.collectionViewLayout invalidateLayout];
    //[self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:YES];
    [self.collectionView headerBeginRefreshing];
}

#pragma mark - Collection View

- (UICollectionViewLayout *)collectionViewLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    if (_currentFinderStyle == UTFinderLayoutCollectionStyle) {
        [flowLayout setItemSize:CGSizeMake(80, 100)];
    } else {
        [flowLayout setItemSize:CGSizeMake(320, 60)];
    }
    
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (_currentFinderStyle) {
        case UTFinderLayoutCollectionStyle:
            return CGSizeMake(80, 100);
            break;
            
        default:
            return CGSizeMake(320, 60);
            break;
    }
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
        
        if (indexPath.row == 0) {
            cell.textField.text = @"";
        } else {
            cell.textField.text = entity.fileName;
        }
        
        if (indexPath.row == 0) {
            if ([[_selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
                cell.imageView.image = [UIImage imageNamed:@"Up_Unavailable"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"Up"];
            }
        } else {
            cell.imageView.image = entity.typeImage;
            
            if (entity.type ==  UTFinderImageType) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.imageView.image = [UTFinderEntity thumbForImageAtPath:entity.filePath destinationSize:CGSizeMake(70, 70)];
                });
            }
        }
        
        return cell;
        
    } else {
        UTTableViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FinderTableCell" forIndexPath:indexPath];
        
        UTFinderEntity *entity = _objects[indexPath.row];
        
        cell.textField.text = entity.fileName;

        cell.detailTextField.text = entity.fileAttrs;
        
        if (indexPath.row == 0) {
            if ([[_selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
                cell.imageView.image = [UIImage imageNamed:@"Up_Unavailable"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"Up"];
            }
        } else {
            cell.imageView.image = entity.typeImage;
            
            if (entity.type ==  UTFinderImageType) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.imageView.image = [UTFinderEntity thumbForImageAtPath:entity.filePath destinationSize:CGSizeMake(50, 50)];
                });
            }
        }
        
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (![[_selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
                
                _selectedItemPath = [_selectedItemPath stringByDeletingLastPathComponent];
                
                _objects = [[UTFinderEntity generateFilesInPath:_selectedItemPath] mutableCopy];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
            }
        });
    } else {
        
        UTFinderFileType fileType = [(UTFinderEntity *)_objects[indexPath.row] type];
        
        if (fileType == UTFinderFolderType) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                _selectedItemPath = [(UTFinderEntity *)_objects[indexPath.row] filePath];
                
                _objects = [[UTFinderEntity generateFilesInPath:_selectedItemPath] mutableCopy];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
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
            [browser setCurrentPhotoIndex:[paths indexOfObject:curPath]];
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:nc animated:YES completion:nil];
            
        }
    }
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
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
