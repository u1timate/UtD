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

@implementation UTFinderCollectionController {
    NSMutableArray *_objects;
}

- (void)viewDidLoad {
    
    if (!_objects) {
        _objects = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    [self.collectionView registerClass:[UTCollectionViewCell class] forCellWithReuseIdentifier:@"FinderCell"];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [self generateFilesInPath:[[NSBundle mainBundle] resourcePath]];
    
    [self.collectionView reloadData];
}

- (void)generateFilesInPath:(NSString *)path {
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
        cell.imageView.image = [UIImage imageNamed:@"Up"];
        
        return cell;
    } else {
    
        cell.textField.text = [(UTFinderEntity *)_objects[indexPath.row - 1] fileName];
        
        cell.imageView.image = [UIImage imageNamed:@"Checkmark"];
        
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"dd");
}

@end
