//
//  MJRefreshHeaderView.m
//  MJRefresh
//
//  Created by mj on 13-2-26.
//  Copyright (c) 2013年 itcast. All rights reserved.
//  下拉刷新

#import "MJRefreshConst.h"
#import "MJRefreshHeaderView.h"
#import "UIView+Extension.h"
#import "UIScrollView+Extension.h"

#import <sys/param.h>
#import <sys/mount.h>

@interface MJRefreshHeaderView()
// 最后的更新时间
@property (nonatomic, strong) NSString *lastUpdateVolumeSize;
@property (nonatomic, weak) UILabel *lastUpdateTimeLabel;
@end

@implementation MJRefreshHeaderView

- (NSString *) freeDiskSpaceInBytes{
    struct statfs buf;
    float freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = buf.f_bsize * buf.f_bfree;
    }
    
    int count = 0;
    
    while (freespace > 1024) {
        freespace = freespace / 1024;
        count ++;
    }
    
    switch (count) {
        case 1:
            return [NSString stringWithFormat:@"%0.2f KB", freespace];
            break;
        
        case 2:
            return [NSString stringWithFormat:@"%0.2f MB", freespace];
            break;
        
        case 3:
            return [NSString stringWithFormat:@"%0.2f GB", freespace];
            break;
        
        case 4:
            return [NSString stringWithFormat:@"%0.2f TB", freespace];
            break;
        
        case 5:
            return [NSString stringWithFormat:@"%0.2f PB", freespace];
            break;
            
        default:
            return [NSString stringWithFormat:@"%0.2f bytes", freespace];
            break;
    }
}

#pragma mark - 控件初始化
/**
 *  时间标签
 */
- (UILabel *)lastUpdateTimeLabel
{
    if (!_lastUpdateTimeLabel) {
        // 1.创建控件
        UILabel *lastUpdateTimeLabel = [[UILabel alloc] init];
        lastUpdateTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        lastUpdateTimeLabel.font = [UIFont boldSystemFontOfSize:12];
        lastUpdateTimeLabel.textColor = MJRefreshLabelTextColor;
        lastUpdateTimeLabel.backgroundColor = [UIColor clearColor];
        lastUpdateTimeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lastUpdateTimeLabel = lastUpdateTimeLabel];
        
        // 2.加载时间
        self.lastUpdateVolumeSize = [[NSUserDefaults standardUserDefaults] objectForKey:MJRefreshHeaderTimeKey];
    }
    return _lastUpdateTimeLabel;
}

+ (instancetype)header
{
    return [[MJRefreshHeaderView alloc] init];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat statusX = 0;
    CGFloat statusY = 0;
    CGFloat statusHeight = self.height * 0.5;
    CGFloat statusWidth = self.width;
    // 1.状态标签
    self.statusLabel.frame = CGRectMake(statusX, statusY, statusWidth, statusHeight);
    
    // 2.时间标签
    CGFloat lastUpdateY = statusHeight;
    CGFloat lastUpdateX = 0;
    CGFloat lastUpdateHeight = statusHeight;
    CGFloat lastUpdateWidth = statusWidth;
    self.lastUpdateTimeLabel.frame = CGRectMake(lastUpdateX, lastUpdateY, lastUpdateWidth, lastUpdateHeight);
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    // 设置自己的位置和尺寸
    self.y = - self.height;
}

#pragma mark - 状态相关
#pragma mark 设置最后的更新时间
- (void)setLastUpdateVolumeSize:(NSString *)lastUpdateVolumeSize
{
    if (lastUpdateVolumeSize != _lastUpdateVolumeSize) {
        
        _lastUpdateVolumeSize = lastUpdateVolumeSize;
    }
    
    // 1.归档
    [[NSUserDefaults standardUserDefaults] setObject:lastUpdateVolumeSize forKey:MJRefreshHeaderTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 2.更新时间
    [self updateTimeLabel];
}

#pragma mark 更新时间字符串
- (void)updateTimeLabel
{
    if (!self.lastUpdateVolumeSize) return;
    
    self.lastUpdateTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Available Capacity: %@", nil), self.lastUpdateVolumeSize];
}
#pragma mark - 监听UIScrollView的contentOffset属性
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // 不能跟用户交互就直接返回
    if (!self.userInteractionEnabled || self.alpha <= 0.01 || self.hidden) return;

    // 如果正在刷新，直接返回
    if (self.state == MJRefreshStateRefreshing) return;

    if ([MJRefreshContentOffset isEqualToString:keyPath]) {
        [self adjustStateWithContentOffset];
    }
}

/**
 *  调整状态
 */
- (void)adjustStateWithContentOffset
{
    // 当前的contentOffset
    CGFloat currentOffsetY = self.scrollView.contentOffsetY;
    // 头部控件刚好出现的offsetY
    CGFloat happenOffsetY = - self.scrollViewOriginalInset.top;
    
    // 如果是向上滚动到看不见头部控件，直接返回
    if (currentOffsetY >= happenOffsetY) return;
    
    if (self.scrollView.isDragging) {
        // 普通 和 即将刷新 的临界点
        CGFloat normal2pullingOffsetY = happenOffsetY - self.height;
        
        if (self.state == MJRefreshStateNormal && currentOffsetY < normal2pullingOffsetY) {
            // 转为即将刷新状态
            self.state = MJRefreshStatePulling;
        } else if (self.state == MJRefreshStatePulling && currentOffsetY >= normal2pullingOffsetY) {
            // 转为普通状态
            self.state = MJRefreshStateNormal;
        }
    } else if (self.state == MJRefreshStatePulling) {// 即将刷新 && 手松开
        // 开始刷新
        self.state = MJRefreshStateRefreshing;
    }
}

#pragma mark 设置状态
- (void)setState:(MJRefreshState)state
{
    // 1.一样的就直接返回
    if (self.state == state) return;
    
    // 2.保存旧状态
    MJRefreshState oldState = self.state;
    
    // 3.调用父类方法
    [super setState:state];
    
    // 4.根据状态执行不同的操作
	switch (state) {
		case MJRefreshStateNormal: // 下拉可以刷新
        {
            // 设置文字
            self.statusLabel.text = [MJRefreshConst MJRefreshHeaderPullToRefresh];
            
            // 刷新完毕
            if (MJRefreshStateRefreshing == oldState) {
                self.arrowImage.transform = CGAffineTransformIdentity;
                // 保存刷新时间
                self.lastUpdateVolumeSize = [self freeDiskSpaceInBytes];
                
                [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
                    self.scrollView.contentInsetTop = self.scrollViewOriginalInset.top;
                }];
            } else {
                // 执行动画
                [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                    self.arrowImage.transform = CGAffineTransformIdentity;
                }];
            }
			break;
        }
            
		case MJRefreshStatePulling: // 松开可立即刷新
        {
            // 设置文字
            self.statusLabel.text = [MJRefreshConst MJRefreshHeaderReleaseToRefresh];
            // 执行动画
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                self.arrowImage.transform = CGAffineTransformMakeRotation(M_PI);
            }];
			break;
        }
            
		case MJRefreshStateRefreshing: // 正在刷新中
        {
            // 设置文字
            self.statusLabel.text = [MJRefreshConst MJRefreshHeaderRefreshing];
            
            // 执行动画
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                // 1.增加65的滚动区域
                CGFloat top = self.scrollViewOriginalInset.top + self.height;
                self.scrollView.contentInsetTop = top;
                
                // 2.设置滚动位置
                self.scrollView.contentOffsetY = - top;
            }];
			break;
        }
            
        default:
            break;
	}
}
@end