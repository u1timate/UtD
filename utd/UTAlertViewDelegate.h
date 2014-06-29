//
//  UTAlertViewDelegate.h
//  utd
//
//  Created by 徐磊 on 14-6-28.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UTAlertViewDelegate : NSObject <UIAlertViewDelegate>

typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);
@property (strong, nonatomic) AlertViewCompletionBlock callback;

+ (void)showAlertView:(UIAlertView *)alertView withCallback:(AlertViewCompletionBlock)callback;


@end
