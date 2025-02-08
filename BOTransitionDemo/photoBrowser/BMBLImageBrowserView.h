//
//  ImageBrowserView.h
//  BOTransitionDemo
//
//  Created by bo on 2025/2/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageBrowserView : UIView

@property (nonatomic, strong, nullable) NSDictionary *dataModel;

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIScrollView *scrollView;

- (void)resetSizeAndInset;

@end

NS_ASSUME_NONNULL_END
