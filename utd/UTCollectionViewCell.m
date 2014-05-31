//
//  UTCollectionViewCell.m
//  utd
//
//  Created by 徐磊 on 14-5-30.
//  Copyright (c) 2014年 xuxulll. All rights reserved.
//

#import "UTCollectionViewCell.h"

@implementation UTCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, self.bounds.size.width - 10, self.bounds.size.width - 10)];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubview:self.imageView];
        
        
        
        self.textField = [[UILabel alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 20, self.bounds.size.width, 18)];
        self.textField.textAlignment = NSTextAlignmentCenter;
        self.textField.font = [UIFont systemFontOfSize:14];
        self.textField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        [self.contentView addSubview:self.textField];
    }
    return self;
}



@end
