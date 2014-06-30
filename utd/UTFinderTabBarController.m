//
//  UTFinderTabBarController.m
//  utd
//
//  Created by 徐磊 on 14-6-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTFinderTabBarController.h"

#import "UTFinderController.h"

@interface UTFinderTabBarController ()

@end

@implementation UTFinderTabBarController {
    NSMutableArray *subViewControllers;
}

- (id)init
{
    self = [super init];
    if (self) {
        UTFinderStyle style = [[NSUserDefaults standardUserDefaults] integerForKey:kUTDefaultFinderStyle];
        
        UTFinderController *finderController = [[UTFinderController alloc] initWithFinderStyle:style];
        
        finderController.navigationController.title = NSLocalizedString(@"Finder", nil);
        
        self.viewControllers = @[finderController.navigationController];
    }
    return self;
}

@end
