//
//  BOTransitionUtility.m
//  BOTransition
//
//  Created by bo on 2020/12/6.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionUtility.h"
#import <objc/runtime.h>
#import "BOTransitionPanGesture.h"

@interface UIResponder (BOTransition)

/*
 获取APP的FirstResponder
 */
+ (UIResponder *)bo_trans_obtainFirstResponder;

@end

@implementation UIResponder (BOTransition)

//需要是week，不应影响原先的释放
static __weak UIResponder *sf_firstResponder = nil;

+ (UIResponder *)bo_trans_obtainFirstResponder {
    //先清空，只获取当前的，确保不能拿上次的
    sf_firstResponder = nil;
    //发送一个没有目标的空消息，借用系统的查找方法找到first响应者
    [[UIApplication sharedApplication] sendAction:@selector(bo_trans_actFirstResponder:)
                                               to:nil
                                             from:nil
                                         forEvent:nil];
    UIResponder *currres = sf_firstResponder;
    //恢复nil
    sf_firstResponder = nil;
    return currres;
}

- (void)bo_trans_actFirstResponder:(id)sender {
    sf_firstResponder = self;
}

@end

@implementation BOTransitionUtility

+ (UIResponder *)obtainFirstResponder {
    return [UIResponder bo_trans_obtainFirstResponder];
}

+ (void)copyOriginMeth:(SEL)originSel newSel:(SEL)newSel class:(Class)cls {
    Method originalMethod = class_getInstanceMethod(cls, originSel);
    class_addMethod(cls,
                    newSel,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod));
}

+ (void)addCATransaction:(NSString *)key completionTask:(void(^)(void))task {
    if (![NSThread isMainThread]) {
        return;
    }
    
    if (task) {
        static NSMutableArray<void(^)(void)> *taskAr;//即用即创建，用完释放
        static BOOL runInCompletionBlock = NO; //正在执行block的标志位，防止外部传入有冲突的mask(在completion再次插入task)
        if (runInCompletionBlock) {
            NSLog(@"⚠️error:bm_addCATransactionCompletionTask的task中再次添加了task");
            return;
        }
        if (!taskAr) {
            taskAr = @[task].mutableCopy;
            [CATransaction begin];
            void (^originblock)(void) = [CATransaction completionBlock];
            [CATransaction setCompletionBlock:^{
                runInCompletionBlock = YES;
                if (originblock) {
                    originblock();
                }
                
                for (void(^thetask)(void) in taskAr) {
                    thetask();
                }
                [taskAr removeAllObjects];
                taskAr = nil;
                runInCompletionBlock = NO;
            }];
            [CATransaction commit];
        } else {
            [taskAr addObject:task];
        }
    }
}

+ (CGRect)rectWithAspectFitForBounding:(CGRect)bounding size:(CGSize)size {
    CGFloat staspect = CGRectGetHeight(bounding) / CGRectGetWidth(bounding);
    CGFloat mvaspect = size.height / size.width;
    CGFloat sw;
    CGFloat sh;
    if (staspect >= mvaspect) {
        sw = CGRectGetWidth(bounding);
        sh = sw * mvaspect;
    } else {
        sh = CGRectGetHeight(bounding);
        sw = sh / mvaspect;
    }
    
    CGRect rt = CGRectMake(CGRectGetMidX(bounding) - sw / 2.f,
                           CGRectGetMidY(bounding) - sh / 2.f,
                           sw, sh);
    return rt;
}

+ (CGRect)rectWithAspectFillForBounding:(CGRect)bounding size:(CGSize)size {
    CGFloat staspect = CGRectGetHeight(bounding) / CGRectGetWidth(bounding);
    CGFloat mvaspect = size.height / size.width;
    CGFloat sw;
    CGFloat sh;
    if (staspect >= mvaspect) {
        sh = CGRectGetHeight(bounding);
        sw = sh / mvaspect;
    } else {
        sw = CGRectGetWidth(bounding);
        sh = sw * mvaspect;
    }
    
    CGRect rt = CGRectMake(CGRectGetMidX(bounding) - sw / 2.f,
                           CGRectGetMidY(bounding) - sh / 2.f,
                           sw, sh);
    return rt;
}

+ (CGFloat)clipMin:(CGFloat)min max:(CGFloat)max val:(CGFloat)val {
    return MAX(min, MIN(max, val));
}

+ (CGFloat)lerpV0:(CGFloat)v0 v1:(CGFloat)v1 t:(CGFloat)t {
    return v0 + (v1 - v0) * t;
}

+ (CGAffineTransform)getTransform:(CGRect)from to:(CGRect)to {
    CGAffineTransform tf = CGAffineTransformMakeTranslation(CGRectGetMidX(to) - CGRectGetMidX(from),
                                                            CGRectGetMidY(to) - CGRectGetMidY(from));
    tf = CGAffineTransformScale(tf, to.size.width / MAX(1.f, from.size.width),
                                to.size.height / MAX(1.f, from.size.height));
    return tf;
}

+ (NSInteger)viewHierarchy:(UIView *)viewA viewB:(UIView *)viewB {
    
    if (viewA.window != viewB.window) {
        return NSNotFound;
    }
    
    NSInteger hier = NSNotFound;
    NSInteger idx = 0;
    for (UIView *theview = viewB;
         nil != theview;
         theview = theview.superview) {
        if (theview == viewA) {
            hier = idx;
            break;
        }
        idx++;
    }
    
    if (NSNotFound == hier) {
        idx = -1;
        for (UIView *theview = viewA.superview;
             nil != theview;
             theview = theview.superview) {
            if (theview == viewB) {
                hier = idx;
                break;
            }
            idx--;
        }
    }
    
    return idx;
}

@end
