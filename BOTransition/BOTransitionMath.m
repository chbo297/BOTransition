//
//  BOTransitionMath.m
//  BOTransition
//
//  Created by bo on 2020/12/6.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionMath.h"
#import <objc/runtime.h>

void bo_addCATransactionCompletionTask(NSString *key, void(^task)(void)) {
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

CGRect botransition_rectWithAspectFitForBounding(CGRect bounding, CGSize size) {
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

CGRect botransition_rectWithAspectFillForBounding(CGRect bounding, CGSize size) {
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

CGFloat botransition_clip(CGFloat min, CGFloat max, CGFloat val) {
    return MAX(min, MIN(max, val));
}

CGFloat botransition_lerp(CGFloat v0, CGFloat v1, CGFloat t) {
    return v0 + (v1 - v0) * t;
}

CGAffineTransform botransition_getTransform(CGRect from, CGRect to) {
    CGAffineTransform tf = CGAffineTransformMakeTranslation(CGRectGetMidX(to) - CGRectGetMidX(from),
                                                            CGRectGetMidY(to) - CGRectGetMidY(from));
    tf = CGAffineTransformScale(tf, to.size.width / MAX(1.f, from.size.width),
                                to.size.height / MAX(1.f, from.size.height));
    return tf;
}
