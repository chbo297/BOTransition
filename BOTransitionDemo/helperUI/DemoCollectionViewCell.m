//
//  DemoCollectionViewCell.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/2.
//

#import "DemoCollectionViewCell.h"


@implementation DemoHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.label];

    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(4);
        make.leading.equalTo(self).offset(9);
    }];
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:19];
        _label.textColor = [UIColor colorWithWhite:0.1 alpha:1];
        _label.textAlignment = NSTextAlignmentLeft;
    }
    return _label;
}

@end

@implementation DemoCollectionViewCell

+ (CGSize)sizeWithWidth:(CGFloat)width {
    CGFloat w = 108;
    return CGSizeMake(w, w + 27);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.imageV];
    [self.contentView addSubview:self.label];

    [self.imageV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(0);
        make.leading.equalTo(self.contentView).offset(0);
        make.trailing.equalTo(self.contentView).offset(0);
        make.height.equalTo(self.contentView.mas_height).offset(-27);
    }];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageV.mas_bottom).offset(2);
        make.leading.equalTo(self.contentView).offset(0);
        make.trailing.equalTo(self.contentView).offset(0);
    }];
}

- (UIImageView *)imageV {
    if (!_imageV) {
        _imageV = [[UIImageView alloc] init];
        _imageV.contentMode = UIViewContentModeScaleAspectFill;
        _imageV.clipsToBounds = YES;
    }
    return _imageV;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:14];
        _label.textColor = [UIColor colorWithWhite:0.2 alpha:1];
        _label.textAlignment = NSTextAlignmentCenter;
    }
    return _label;
}


@end
