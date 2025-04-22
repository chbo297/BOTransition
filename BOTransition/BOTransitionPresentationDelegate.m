//
//  BOTransitionPresentationDelegate.m
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionPresentationDelegate.h"
#import "UIViewController+BOTransition.h"
#import "BOTransitioning.h"

@interface BOTransitionPresentationDelegate ()

@property (nonatomic, strong) BOTransitioning *transitioning;

@end

@implementation BOTransitionPresentationDelegate

- (BOTransitioning *)transitioning {
    if (!_transitioning) {
        _transitioning = [BOTransitioning transitioningWithType:BOTransitionTypeModalPresentation];
    }
    return _transitioning;
}

#pragma mark - 动画
- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                           presentingController:(UIViewController *)presenting
                                                                               sourceController:(UIViewController *)source {
    BOTransitionConfig *tconfig = presented.bo_transitionConfig;
    if (tconfig && !tconfig.moveInUseOrigin) {
        self.transitioning.transitionAct = BOTransitionActMoveIn;
        return self.transitioning;
    }
    
    return nil;
}

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BOTransitionConfig *tconfig = dismissed.bo_transitionConfig;
    if (tconfig && !tconfig.moveOutUseOrigin) {
        self.transitioning.transitionAct = BOTransitionActMoveOut;
        return self.transitioning;
    }
    
    return nil;
}

#pragma mark - 可交互
////modelPresent弹出目前不支持交互
//- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
//    if (self.transitioning.triggerInteractiveTransitioning) {
//        self.transitioning.transitionAct = BOTransitionActMoveIn;
//        return self.transitioning;
//    } else {
//        return nil;
//    }
//}

- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    if (self.transitioning.triggerInteractiveTransitioning) {
        self.transitioning.transitionAct = BOTransitionActMoveOut;
        return self.transitioning;
    } else {
        return nil;
    }
}

@end
