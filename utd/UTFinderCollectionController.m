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
    
    NSString *_selectedItemPath;
    
}

- (void)viewDidLoad {
    
    [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCell"];
    self.collectionView.alwaysBounceVertical = YES;
    
    [self addHeader];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        _selectedItemPath = [[NSBundle mainBundle] resourcePath];
        
        [self generateFilesInPath:_selectedItemPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
}

- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    // 添加下拉刷新头部控件
    [self.collectionView addHeaderWithCallback:^{
        // 进入刷新状态就会回调这个Block
        
        
        // 模拟延迟加载数据，因此2秒后才调用）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [vc.collectionView reloadData];
            // 结束刷新
            [vc.collectionView headerEndRefreshing];
        });
    }];
}

- (void)generateFilesInPath:(NSString *)path {
    
    if (!_objects || _objects.count > 0) {
        _objects = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *e = [fileManager enumeratorAtPath:path];
    
    NSString *file;
    
    while (file = [e nextObject]) {
        [e skipDescendants];
        UTFinderEntity *entity = [[UTFinderEntity alloc] init];
        entity.fileName = file;
        entity.filePath = [path stringByAppendingFormat:@"/%@", file];
        
        [_objects addObject:entity];
    }
}

- (UICollectionViewLayout *)collectionViewLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(80, 100)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    return flowLayout;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _objects.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UTCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FinderCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        
        if ([[_selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
            cell.imageView.image = [UIImage imageNamed:@"Up_Unavailable"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"Up"];
        }
        cell.textField.text = @"";
        return cell;
    } else {
    
        cell.textField.text = [(UTFinderEntity *)_objects[indexPath.row - 1] fileName];
        
        cell.imageView.image = [UIImage imageNamed:@"Checkmark"];
        
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (![[_selectedItemPath stringByDeletingLastPathComponent] isEqualToString:@"/var/mobile/Applications"]) {
                
                _selectedItemPath = [_selectedItemPath stringByDeletingLastPathComponent];
                
                [self generateFilesInPath:_selectedItemPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
            }
        });
    } else {
        
        BOOL isDir = [(UTFinderEntity *)_objects[indexPath.row - 1] isDirectory];
        
        if (isDir) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                _selectedItemPath = [(UTFinderEntity *)_objects[indexPath.row - 1] filePath];
                
                [self generateFilesInPath:_selectedItemPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
            });
        }
    }
}

@end
