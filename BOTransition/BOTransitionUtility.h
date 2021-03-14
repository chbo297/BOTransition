//
//  BOTransitionUtility.h
//  BOTransition
//
//  Created by bo on 2020/12/6.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BOTransitionUtility : NSObject

+ (UIResponder *)obtainFirstResponder;

+ (void)swizzleMethodTargetCls:(Class)targetCls originalSel:(SEL)originalSel
                        srcCls:(Class)srcCls srcSel:(SEL)srcSel;
+ (void)copyOriginMeth:(SEL)originSel newSel:(SEL)newSel class:(Class)cls;

+ (CGRect)rectWithAspectFitForBounding:(CGRect)bounding size:(CGSize)size;
+ (CGRect)rectWithAspectFillForBounding:(CGRect)bounding size:(CGSize)size;

+ (CGFloat)clipMin:(CGFloat)min max:(CGFloat)max val:(CGFloat)val;
+ (CGFloat)lerpV0:(CGFloat)v0 v1:(CGFloat)v1 t:(CGFloat)t;

+ (CGAffineTransform)getTransform:(CGRect)from to:(CGRect)to;

+ (NSInteger)viewHierarchy:(UIView *)viewA viewB:(UIView *)viewB;

@end
