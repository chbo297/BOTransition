//
//  BMBLImageBrowserView.m
//  BOTransitionDemo
//
//  Created by bo on 2025/2/6.
//

#import "BMBLImageBrowserView.h"
#import "BOTransitionUtility.h"
#import "BOExtension.h"

@interface BMBLImageBrowserView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSNumber *currFillZoomScale;
@property (nonatomic, strong) NSNumber *zoom_lastJiesuanScale;
@property (nonatomic, assign) BOOL hasBigChange;
@property (nonatomic, strong) NSNumber *zoomCankaoWidth;
@property (nonatomic, strong) NSNumber *zoomChangeMax;
@property (nonatomic, assign) BOOL needsZoomFill;

@end

@implementation BMBLImageBrowserView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setDataModel:(NSDictionary *)dataModel {
    _dataModel = dataModel;
    UIImage *spimage = [dataModel objectForKey:@"image"];
    if (![spimage isKindOfClass:[UIImage class]]) {
        spimage = nil;
    }
    self.imageView.image = spimage;
    NSString *image_url = [dataModel objectForKey:@"image_url"];
    if ([image_url isKindOfClass:[NSString class]]) {
//        [self.imageView bo]
    }
}

- (void)setupUI {
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.imageView];
    
    self.scrollView.delegate = self;
    
    [self i_layoutSubviews];
}

- (void)resetSizeAndInset {
    UIEdgeInsets theinsets = UIEdgeInsetsZero;
    CGSize spsz = self.scrollView.frame.size;
    CGSize areasz = self.scrollView.contentSize;
    CGFloat hspace = 0;
    CGFloat vspace = 0;
    if (areasz.width < spsz.width) {
        hspace = (spsz.width - areasz.width) / 2.0;
    }
    if (areasz.height < spsz.height) {
        vspace = (spsz.height - areasz.height) / 2.0;
    }
    
    theinsets = UIEdgeInsetsMake(vspace, hspace, vspace, hspace);
    
    UIEdgeInsets currinsets = self.scrollView.contentInset;
    if (currinsets.top != theinsets.top
        || currinsets.left != theinsets.left
        || currinsets.bottom != theinsets.bottom
        || currinsets.right != theinsets.right) {
        self.scrollView.contentInset = theinsets;
    }
}


- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.zoom_lastJiesuanScale = @(scrollView.zoomScale);
    self.hasBigChange = NO;
}

/*
 todo  刚好zoommax时固定+震动
 盘点一次滑动过程中，zoom变化超过超过一定阈值，到达max时震动一下，记录应该在停止时固定max，超出阈值再重置清空
 */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self resetSizeAndInset];
    
    CGFloat changeyuzhi = 30.0;
    if (self.needsZoomFill) {
        if (fabs(scrollView.zoomScale - self.currFillZoomScale.floatValue) * self.zoomCankaoWidth.floatValue >= changeyuzhi) {
            self.needsZoomFill = NO;
        }
    } else {
        if (nil != self.currFillZoomScale) {
            if (!self.hasBigChange) {
                if (fabs(scrollView.zoomScale - self.zoom_lastJiesuanScale.floatValue) * self.zoomCankaoWidth.floatValue >= changeyuzhi) {
                    self.hasBigChange = YES;
                }
            }
            
            if (self.hasBigChange
                && fabs(scrollView.zoomScale - self.currFillZoomScale.floatValue) * self.zoomCankaoWidth.floatValue < changeyuzhi) {
                self.needsZoomFill = YES;
                UIImpactFeedbackGenerator *impactfb = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                [impactfb impactOccurred];
                
                self.zoom_lastJiesuanScale = self.currFillZoomScale;
                self.hasBigChange = NO;
            }
        }
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (self.needsZoomFill) {
        if (nil != self.currFillZoomScale) {
            if (scale != self.currFillZoomScale.floatValue) {
                [scrollView setZoomScale:self.currFillZoomScale.floatValue animated:YES];
            }
        }
        self.needsZoomFill = NO;
    }
    
    if (scale < 1) {
        
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"~~~offset:%@", @(self.scrollView.contentOffset));
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self i_layoutSubviews];
}

- (void)i_layoutSubviews {
    CGSize totalsz = self.bounds.size;
    if (totalsz.width == 0
        || totalsz.height == 0) {
        return;
    }
    CGRect totalrt = (CGRect){CGPointZero, totalsz};
    CGSize imgsz = CGSizeZero;
    if (self.imageView.image) {
        imgsz = self.imageView.image.size;
    }
    
    if (imgsz.width == 0
        || imgsz.height == 0) {
        return;
    }
    
    CGRect targetrt = [BOTransitionUtility rectWithAspectFitForBounding:totalrt size:imgsz];
    
    self.scrollView.bo_frame = totalrt;
    self.imageView.bo_frame = (CGRect){CGPointZero, targetrt.size};
    self.scrollView.contentSize = targetrt.size;
    self.scrollView.zoomScale = 1;
    self.scrollView.minimumZoomScale = 1;
    
    CGSize targetsz = targetrt.size;
    CGFloat showratio = totalsz.height / totalsz.width;
    CGFloat targetratio = targetsz.height / targetsz.width;
    CGFloat maxzoom = 1.0;
    CGFloat guanjianbian = 0.0;
    if (targetratio > showratio) {
        maxzoom = totalsz.width / targetsz.width;
        guanjianbian = targetsz.width;
    } else {
        maxzoom = totalsz.height / targetsz.height;
        guanjianbian = targetsz.height;
    }
    
    self.currFillZoomScale = @(maxzoom);
    self.needsZoomFill = NO;
    self.zoomCankaoWidth = @(guanjianbian);
    CGFloat screenscale = [UIScreen mainScreen].scale;
    
    self.scrollView.maximumZoomScale = maxzoom + screenscale;
    
    [self resetSizeAndInset];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.bo_pointInsideExtension = UIEdgeInsetsMake(-1000, -1000, -1000, -1000);
        _scrollView.clipsToBounds = NO;
    }
    return _scrollView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = YES;
        _imageView.clipsToBounds = NO;
    }
    return _imageView;
}

- (BOOL)makeImageShowForRect:(CGRect)showRect {
    CGFloat sfimgvwidth = self.imageView.frame.size.width;
    CGFloat imwidth = CGRectGetWidth(showRect);
    if (sfimgvwidth > 0) {
        CGFloat mayscale = imwidth / sfimgvwidth;
        
        CGPoint mayoffset = CGPointMake(- CGRectGetMinX(showRect),
                                        - CGRectGetMinY(showRect));
        [self.scrollView setZoomScale:mayscale animated:NO];
        [self resetSizeAndInset];
        [self.scrollView setContentOffset:mayoffset animated:NO];
        return YES;
    }
    return NO;
}

- (void)execBounces {
    UIScrollView *scrollView = self.scrollView;
    CGSize bdsz = scrollView.bounds.size;
    UIEdgeInsets insets = scrollView.adjustedContentInset;
    CGSize contentsz = scrollView.contentSize;
    CGFloat minoffsetx = -insets.left;
    CGFloat maxoffsetx = contentsz.width + insets.right - bdsz.width;
    if (maxoffsetx < minoffsetx) {
        maxoffsetx = minoffsetx;
    }
    CGFloat minoffsety = -insets.top;
    CGFloat maxoffsety = contentsz.height + insets.bottom - bdsz.height;
    if (maxoffsety < minoffsety) {
        maxoffsety = minoffsety;
    }
    
    CGPoint curroffset = scrollView.contentOffset;
    CGPoint shouldoffset = curroffset;
    if (shouldoffset.x < minoffsetx) {
        shouldoffset.x = minoffsetx;
    }
    if (shouldoffset.x > maxoffsetx) {
        shouldoffset.x = maxoffsetx;
    }
    if (shouldoffset.y < minoffsety) {
        shouldoffset.y = minoffsety;
    }
    if (shouldoffset.y > maxoffsety) {
        shouldoffset.y = maxoffsety;
    }
    
    if (!CGPointEqualToPoint(shouldoffset, curroffset)) {
        [scrollView setContentOffset:shouldoffset animated:YES];
    }
}

@end
