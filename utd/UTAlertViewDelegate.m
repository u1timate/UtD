//
//  UTAlertViewDelegate.m
//  utd
//
//  Created by 徐磊 on 14-6-28.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTAlertViewDelegate.h"

@implementation UTAlertViewDelegate

@synthesize callback;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    callback(buttonIndex);
}

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback {
    __block UTAlertViewDelegate *delegate = [[UTAlertViewDelegate alloc] init];
    alertView.delegate = delegate;
    delegate.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
        
#pragma clang diagnostic push and #pragma clang diagnostic ignored "-Warc-retain-cycles"
        delegate = nil;
#pragma clang diagnostic pop
    };
    [alertView show];
}

@end
