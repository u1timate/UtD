//
//  MJRefreshConst.m
//  MJRefresh
//
//  Created by mj on 14-1-3.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "MJRefreshConst.h"

const CGFloat MJRefreshViewHeight = 64.0;
const CGFloat MJRefreshFastAnimationDuration = 0.25;
const CGFloat MJRefreshSlowAnimationDuration = 0.4;

NSString *const MJRefreshBundleName = @"MJRefresh.bundle";

NSString *const MJRefreshFooterPullToRefresh = @"上拉以加载更多数据";
NSString *const MJRefreshFooterReleaseToRefresh = @"松开立即加载更多数据";
NSString *const MJRefreshFooterRefreshing = @"正在加载数据...";

NSString *const MJRefreshHeaderTimeKey = @"MJRefreshHeaderView";

NSString *const MJRefreshContentOffset = @"contentOffset";
NSString *const MJRefreshContentSize = @"contentSize";


@implementation MJRefreshConst

+ (NSString *)MJRefreshHeaderPullToRefresh {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
        return NSLocalizedString(@"Pull to Refresh", nil);
    }
    return NSLocalizedString(@"Pull to Go Upper Folder", nil);
}

+ (NSString *)MJRefreshHeaderReleaseToRefresh {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUTDefaultPullToRefresh]) {
        return NSLocalizedString(@"Release to Refresh Now", nil);
    }
    return NSLocalizedString(@"Release to Go Upper Folder Now", nil);
}

+ (NSString *)MJRefreshHeaderRefreshing {
    return NSLocalizedString(@"Loading Data...", nil);
}

@end