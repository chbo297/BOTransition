//
//  BOTransitionUtility.m
//  BOTransition
//
//  Created by bo on 2020/12/6.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionUtility.h"
#import <objc/runtime.h>

@implementation BOTransitionUtility

+ (void)swizzleMethodTargetCls:(Class)targetCls originalSel:(SEL)originalSel
                        srcCls:(Class)srcCls srcSel:(SEL)srcSel {
    Method originalMethod = class_getInstanceMethod(targetCls, originalSel);
    Method swizzledMethod = class_getInstanceMethod(srcCls, srcSel);
    BOOL didAddMethod =\
    class_addMethod(targetCls, originalSel, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(targetCls, srcSel, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)copyOriginMeth:(SEL)originSel newSel:(SEL)newSel class:(Class)cls {
    Method originalMethod = class_getInstanceMethod(cls, originSel);
    class_addMethod(cls,
                    newSel,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod));
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
    
    return hier;
}

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
                                   userInfo:(nullable NSDictionary *)userInfo {
    //不校验类型，外部保障
    NSString *key = [userInfo objectForKey:@"key"];
    if (!key) {
        key = @"default";
    }
    
    NSNumber *actnum = [userInfo objectForKey:@"act"];
    NSInteger act = 0;
    if (nil != actnum) {
        act = actnum.integerValue;
    }
    
    static NSMutableDictionary<NSString *, NSMutableArray<void (^)(void)> *> *meth_doAfterScreenUpdatesBlockDic;
    
    BOOL hasadd = NO;
    switch (act) {
        case 0:
        case 1: {
            if (!block) {
                return;
            }
            
            //0和1需要添加，确保meth_doAfterScreenUpdatesBlockDic被创建
            if (!meth_doAfterScreenUpdatesBlockDic) {
                meth_doAfterScreenUpdatesBlockDic = @{}.mutableCopy;
            }
            
            //获取key对应的容器数组，如数组还没有则创建
            NSMutableArray<void (^)(void)> *bkar = [meth_doAfterScreenUpdatesBlockDic objectForKey:key];
            if (!bkar) {
                bkar = @[].mutableCopy;
                [meth_doAfterScreenUpdatesBlockDic setObject:bkar forKey:key];
            }
            
            //act为1表示要清空之前的
            if (1 == act) {
                [bkar removeAllObjects];
            }
            
            //添加进去
            [bkar addObject:block];
            hasadd = YES;
        }
            break;
        case 2: {
            if (meth_doAfterScreenUpdatesBlockDic) {
                [meth_doAfterScreenUpdatesBlockDic removeObjectForKey:key];
            }
        }
            break;
        case 3: {
            [meth_doAfterScreenUpdatesBlockDic removeAllObjects];
        }
            break;
            
        default:
            break;
    }
    
    static BOOL meth_hasDoAfterScreenUpdatesTask = NO;
    
    //如果有加新任务，且还没有启动observer的任务，新建任务并启动
    if (hasadd && !meth_hasDoAfterScreenUpdatesTask) {
        meth_hasDoAfterScreenUpdatesTask = YES;
        //添加kCFRunLoopBeforeWaiting末尾的监听，往mainthread里丢任务给下个runloop
        CFRunLoopRef rlref = CFRunLoopGetMain();
        CFRunLoopObserverRef observerref =\
        CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(),
                                           kCFRunLoopBeforeWaiting,
                                           false,
                                           0xFFFFFF, // after CATransaction(2000000)
                                           ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            meth_hasDoAfterScreenUpdatesTask = NO;
            
            NSMutableArray *doblockar;
            //执行待办事件
            if (meth_doAfterScreenUpdatesBlockDic.count > 0) {
                /*
                 不能直接遍历meth_doAfterScreenUpdatesBlockDic执行block，防止其block内部执行addOperationBlockAfterScreenUpdates产生冲突
                 取出来后给下一个runloop执行，然后清空并格式化当前meth_doAfterScreenUpdatesBlockDic
                 */
                doblockar = @[].mutableCopy;
                [meth_doAfterScreenUpdatesBlockDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                                                       NSMutableArray<void (^)(void)> * _Nonnull obj,
                                                                                       BOOL * _Nonnull stop) {
                    if (obj.count > 0) {
                        [doblockar addObjectsFromArray:obj];
                    }
                }];
                [meth_doAfterScreenUpdatesBlockDic removeAllObjects];
                meth_doAfterScreenUpdatesBlockDic = nil;
            }
            
            /*
             异步释放observer（防止在此时系统内部对observer做一些操作，虽然测试发现似乎没有）
             
             把block丢过去执行，根据runloop源码可知，此时丢block会在下一个runloop去执行。
             不在此时直接执行block是防止里有业务在block里修改UI，若后续没有事件将runloop唤醒，那UI的修改可能会由于没有渲染时机而延迟生效到下次有事件
             */
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                //移除监听（repeat为NO是系统似乎会自动移除）但文档只说会invalid没写明一定移除，这里显式移除一下吧，多一处也没问题
                if (CFRunLoopContainsObserver(rlref, observer, kCFRunLoopCommonModes)) {
                    CFRunLoopRemoveObserver(rlref, observer, kCFRunLoopCommonModes);
                }
                //释放observer
                CFRelease(observer);
                
                if (doblockar) {
                    //执行这些block
                    [doblockar enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(void),
                                                            NSUInteger idx,
                                                            BOOL * _Nonnull stop) {
                        obj();
                    }];
                }
            }];
            
        });
        
        CFRunLoopAddObserver(rlref, observerref, kCFRunLoopCommonModes);
    }
    
}

@end
