//
//  UIViewController+BOTransition.m
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import "UIViewController+BOTransition.h"
#import <objc/runtime.h>
#import "BOTransitionPresentationDelegate.h"

@implementation UIViewController (BOTransition)

- (BOTransitionConfig *)bo_transitionConfig {
    BOTransitionConfig *value = objc_getAssociatedObject(self, @selector(bo_transitionConfig));
    if ([value isKindOfClass:[BOTransitionConfig class]]) {
        return value;
    } else {
        return nil;
    }
}

- (void)setBo_transitionConfig:(BOTransitionConfig *)bo_transitionConfig {
    objc_setAssociatedObject(self, @selector(bo_transitionConfig),
                             bo_transitionConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    bo_transitionConfig.targetVC = self;
    
    if (bo_transitionConfig && bo_transitionConfig.applyToModalPresentation) {
        //如果需要应用到presentation方式，设置modalPresentationStyle以及transitioningDelegate
        //并把BOTransitionPresentationDelegate找一个地方存储，防止其释放
        if (bo_transitionConfig.presentOverTheContext) {
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        } else {
            self.modalPresentationStyle = UIModalPresentationCustom;
        }
        
        if (!bo_transitionConfig.presentTransitioningDelegate
            || ![bo_transitionConfig.presentTransitioningDelegate isKindOfClass:[BOTransitionPresentationDelegate class]]) {
            bo_transitionConfig.presentTransitioningDelegate = [BOTransitionPresentationDelegate new];
        }
        self.transitioningDelegate = bo_transitionConfig.presentTransitioningDelegate;
    } else {
        //如果不需要应用到presentation方式，清空presentTransitioningDelegate
        bo_transitionConfig.presentTransitioningDelegate = nil;
        if (self.transitioningDelegate &&
            [self.transitioningDelegate isKindOfClass:[BOTransitionPresentationDelegate class]]) {
            //猜测当前transitioningDelegate是由此方法设置的，清空
            self.transitioningDelegate = nil;
        }
        
    }
}

- (void)bo_transitionWillCompletion:(NSDictionary *)subInfo {
    
}

@end
