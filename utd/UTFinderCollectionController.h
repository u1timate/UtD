//
//  UTFinderCollectionController.h
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UTFinderController.h"

static UIProgressView *progressIndicator;

@interface UTFinderCollectionController : UICollectionViewController <UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UTFinderController *myParentController;

@property (strong, nonatomic) UIToolbar *editingToolbar;

- (void)setFinderEditing:(id)sender;
- (void)refreshCurrentFolder;
@end
