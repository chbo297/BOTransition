//
//  BOTransitionEffectMovingImp.m
//  BOTransition
//
//  Created by bo on 2020/12/7.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionEffectFadeImp.h"
#import "BOTransitioning.h"

@implementation BOTransitionEffectFadeImp

- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements
                 subInfo:(nullable NSDictionary *)subInfo {
    id<UIViewControllerContextTransitioning> context = transitioning.transitionContext;
    UIView *container = context.containerView;
    if (!context ||
        !container) {
        return;
    }
    
    switch (step) {
        case BOTransitionStepInstallElements: {
            BOTransitionElement *boardelement = [BOTransitionElement elementWithType:BOTransitionElementTypeBoard];
            boardelement.transitionView = transitioning.moveTransBoard;
            boardelement.alphaAllow = YES;
            NSNumber *alphaCalPow_num = [self.configInfo objectForKey:@"alphaCalPow"];
            if (nil != alphaCalPow_num) {
                boardelement.alphaCalPow = alphaCalPow_num.floatValue;
            }
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                boardelement.alphaFrom = 0;
                boardelement.alphaTo = 1;
            } else {
                boardelement.alphaFrom = 1;
                boardelement.alphaTo = 0;
            }
            
            [elements addObject:boardelement];
        }
            break;
        default:
            break;
    }
    
}

@end
