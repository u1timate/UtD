//
//  UTFinderCollectionController.h
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MWPhotoBrowser.h"

static UIProgressView *progressIndicator;

@interface UTFinderCollectionController : UICollectionViewController <UICollectionViewDelegateFlowLayout, MWPhotoBrowserDelegate, UIToolbarDelegate, UIActionSheetDelegate>


@end
