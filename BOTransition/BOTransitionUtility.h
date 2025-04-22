//
//  BOTransitionUtility.h
//  BOTransition
//
//  Created by bo on 2020/12/6.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BOTransitionUtility : NSObject

+ (void)swizzleMethodTargetCls:(Class)targetCls originalSel:(SEL)originalSel
                        srcCls:(Class)srcCls srcSel:(SEL)srcSel;
+ (void)copyOriginMeth:(SEL)originSel newSel:(SEL)newSel class:(Class)cls;

+ (CGRect)rectWithAspectFitForBounding:(CGRect)bounding size:(CGSize)size;
+ (CGRect)rectWithAspectFillForBounding:(CGRect)bounding size:(CGSize)size;

+ (CGFloat)clipMin:(CGFloat)min max:(CGFloat)max val:(CGFloat)val;
+ (CGFloat)lerpV0:(CGFloat)v0 v1:(CGFloat)v1 t:(CGFloat)t;

+ (CGAffineTransform)getTransform:(CGRect)from to:(CGRect)to;

+ (NSInteger)viewHierarchy:(UIView *)viewA viewB:(UIView *)viewB;

/*
 在下一个runloop去执行这个block
 
 @block 当userInfo传nil或其中的act为1（替换添加）时，block为必传，否则方法调用无效
 
 @userInfo 传nil时，act默认为0
 
 @{
 act: NSNumber(NSInteger)
 0增量添加（默认） 1添加前先清空这个key下已有的内容 2清空这个key下的内容 3清空所有内容
 
 key: NSString
 不传的话默认为@"default"
 可以通过key和act管理传入的block
 }
 */
+ (void)addOperationBlockAfterScreenUpdates:(nullable void (^)(void))block
                                   userInfo:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
