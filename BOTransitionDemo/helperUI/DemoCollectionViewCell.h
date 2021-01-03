//
//  DemoCollectionViewCell.h
//  BOTransitionDemo
//
//  Created by bo on 2021/1/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageV;
@property (nonatomic, strong) UILabel *label;

+ (CGSize)sizeWithWidth:(CGFloat)width;

@end

@interface DemoHeader : UICollectionReusableView

@property (nonatomic, strong) UILabel *label;

@end

NS_ASSUME_NONNULL_END
