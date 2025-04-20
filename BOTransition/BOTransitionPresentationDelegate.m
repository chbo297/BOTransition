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
#import "BOTransitionConfig.h"

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

- (BOTransitioning *)currTransitioning {
    return _transitioning;
}

#pragma mark - 动画
- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                           presentingController:(UIViewController *)presenting
                                                                               sourceController:(UIViewController *)source {
    BOTransitionConfig *tconfig = presented.bo_transitionConfig;
    if (tconfig && !tconfig.moveInUseOrigin) {
        BOTransitioning *use_tran;
        if (tconfig.preTransition) {
            use_tran = tconfig.preTransition;
            _transitioning = use_tran;
        } else {
            use_tran = self.transitioning;
        }
        
        use_tran.transitionAct = BOTransitionActMoveIn;
        return use_tran;
    }
    
    return nil;
}

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BOTransitionConfig *tconfig = dismissed.bo_transitionConfig;
    if (tconfig && !tconfig.moveOutUseOrigin) {
        BOTransitioning *use_tran;
        if (tconfig.preTransition) {
            use_tran = tconfig.preTransition;
            _transitioning = use_tran;
        } else {
            use_tran = self.transitioning;
        }
        
        use_tran.transitionAct = BOTransitionActMoveOut;
        return use_tran;
    }
    
    return nil;
}

#pragma mark - 可交互

- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    if (self.transitioning.triggerInteractiveTransitioning) {
        self.transitioning.transitionAct = BOTransitionActMoveIn;
        return self.transitioning;
    } else {
        return nil;
    }
}

- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    if (self.transitioning.triggerInteractiveTransitioning) {
        self.transitioning.transitionAct = BOTransitionActMoveOut;
        return self.transitioning;
    } else {
        return nil;
    }
}

@end
