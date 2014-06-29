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
    self = [super initWithFrame:CGRectMake(0, 0, 80, 100)];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 70, 70)];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubview:self.imageView];
        
        self.textField = [[UILabel alloc] initWithFrame:CGRectMake(5, 75, 70, 18)];
        self.textField.textAlignment = NSTextAlignmentCenter;
        self.textField.font = [UIFont systemFontOfSize:14];
        self.textField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        [self.contentView addSubview:self.textField];
        
        
    }
    return self;
}

@end

@implementation UTTableViewCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 60)];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubview:self.imageView];
        
        self.textField = [[UILabel alloc] initWithFrame:CGRectMake(60, 8, 255, 18)];
        self.textField.textAlignment = NSTextAlignmentNatural;
        self.textField.font = [UIFont systemFontOfSize:14];
        self.textField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        [self.contentView addSubview:self.textField];
        
        self.detailTextField = [[UILabel alloc] initWithFrame:CGRectMake(60, 30, 255, 18)];
        self.detailTextField.textAlignment = NSTextAlignmentNatural;
        self.detailTextField.font = [UIFont systemFontOfSize:14];
        self.detailTextField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        [self.contentView addSubview:self.detailTextField];
    }
    return self;
}

@end
