//
//  UTFinderTableViewController.h
//  utd
//
//  Created by 徐磊 on 14-6-29.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UTFinderController.h"

@interface UTFinderTableViewController : UITableViewController

@property (strong, nonatomic) UIToolbar *editingToolbar;
@property (strong, nonatomic) UISegmentedControl *segment;
@property (strong, nonatomic) UTFinderController *myParentController;
@property (strong, nonatomic) UILabel *textLabel;

- (void)hideToolBar;

@end


@interface UTTableViewCell : UITableViewCell

@end