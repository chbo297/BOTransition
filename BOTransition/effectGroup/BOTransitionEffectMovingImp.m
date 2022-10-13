//
//  BOTransitionEffectMovingImp.m
//  BOTransition
//
//  Created by bo on 2020/12/7.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionEffectMovingImp.h"
#import "BOTransitioning.h"

@implementation BOTransitionEffectMovingImp

- (NSDictionary *)defaultConfigInfo {
    return @{
        @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionRight),
        @"direction": @(UIRectEdgeRight),
    };
}

- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements {
    id<UIViewControllerContextTransitioning> context = transitioning.transitionContext;
    UIView *container = context.containerView;
    if (!context ||
        !container) {
        return;
    }
    
    switch (step) {
        case BOTransitionStepInstallElements: {
            BOTransitionElement *boardelement = [BOTransitionElement elementWithType:BOTransitionElementTypeBoard];
            CGRect movedrt;
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                movedrt = [transitioning.transitionContext finalFrameForViewController:transitioning.moveVC];
            } else {
                movedrt = [transitioning.transitionContext initialFrameForViewController:transitioning.moveVC];
            }
            
            NSDictionary *configinfo = self.configInfo ? : [self defaultConfigInfo];
            
            NSNumber *directionval = configinfo[@"direction"];
            UIRectEdge direction;
            if (nil != directionval) {
                direction = directionval.unsignedIntegerValue;
            } else {
                direction = UIRectEdgeRight;
            }
            CGRect outrt = movedrt;
            NSNumber *moveOutAdaptionGesval = configinfo[@"moveOutAdaptionGes"];
            if (transitionInfo.interactive
                && nil != moveOutAdaptionGesval
                && moveOutAdaptionGesval.boolValue) {
                switch (transitioning.transitionGes.triggerDirectionInfo.mainDirection) {
                    case UISwipeGestureRecognizerDirectionUp:
                        direction = UIRectEdgeTop;
                        break;
                    case UISwipeGestureRecognizerDirectionLeft:
                        direction = UIRectEdgeLeft;
                        break;
                    case UISwipeGestureRecognizerDirectionDown:
                        direction = UIRectEdgeBottom;
                        break;
                    case UISwipeGestureRecognizerDirectionRight:
                        direction = UIRectEdgeRight;
                        break;
                    default:
                        break;
                }
            }
            switch (direction) {
                case UIRectEdgeTop: {
                    //往上滑的添加下部的栅栏，防止滑动下边的屏幕外，下同
                    boardelement.frameBarrierInContainer = UIRectEdgeBottom;
                    outrt.origin.y = CGRectGetMinY(container.bounds) - CGRectGetHeight(movedrt);
                }
                    break;
                case UIRectEdgeLeft: {
                    boardelement.frameBarrierInContainer = UIRectEdgeRight;
                    outrt.origin.x = CGRectGetMinX(container.bounds) - CGRectGetWidth(movedrt);
                }
                    break;
                case UIRectEdgeBottom: {
                    boardelement.frameBarrierInContainer = UIRectEdgeTop;
                    outrt.origin.y = CGRectGetMaxY(container.bounds);
                }
                    break;
                case UIRectEdgeRight: {
                    boardelement.frameBarrierInContainer = UIRectEdgeLeft;
                    outrt.origin.x = CGRectGetMaxX(container.bounds);
                }
                    break;
                default: {
                    //error
                    NSLog(@"~~~！！！错误CGRect outrt = movedrt;");
                    outrt.origin.x = CGRectGetMaxX(container.bounds);
                }
                    break;
            }
            
            boardelement.transitionView = transitioning.moveTransBoard;
            boardelement.frameAllow = YES;
            boardelement.frameShouldPin = NO;
            boardelement.frameOrigin = movedrt;
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                boardelement.frameFrom = outrt;
                boardelement.frameTo = movedrt;
            } else {
                boardelement.frameFrom = movedrt;
                boardelement.frameTo = outrt;
            }
            
            [elements addObject:boardelement];
            BOOL hasBG = YES;
            NSNumber *bgval = [self.configInfo objectForKey:@"bg"];
            if (nil != bgval) {
                hasBG = bgval.boolValue;
            }
            if (hasBG) {
                UIView *bgv = transitioning.checkAndInitCommonBg;
                bgv.frame = container.bounds;
                BOTransitionElement *bgelement = [BOTransitionElement elementWithType:BOTransitionElementTypeBg];
                bgelement.transitionView = bgv;
                bgelement.alphaAllow = YES;
                bgelement.alphaCalPow = 4;
                if (BOTransitionActMoveIn == transitioning.transitionAct) {
                    bgelement.alphaFrom = 0;
                    bgelement.alphaTo = 1;
                } else {
                    bgelement.alphaFrom = 1;
                    bgelement.alphaTo = 0;
                }
                [bgelement addToStep:BOTransitionStepInstallElements
                               block:^(BOTransitioning * _Nonnull blockTrans,
                                       BOTransitionStep step,
                                       BOTransitionElement * _Nonnull transitionElement,
                                       BOTransitionInfo transitionInfo,
                                       NSDictionary * _Nullable subInfo) {
                    UIView *blockcontainer = blockTrans.transitionContext.containerView;
                    transitionElement.transitionView.frame = blockcontainer.bounds;
                    [blockcontainer insertSubview:transitionElement.transitionView belowSubview:transitioning.moveTransBoard];
                }];
                
                if (BOTransitionActMoveOut == transitioning.transitionAct) {
                    [bgelement addToStep:BOTransitionStepFinished
                                   block:^(BOTransitioning * _Nonnull blockTrans,
                                           BOTransitionStep step,
                                           BOTransitionElement * _Nonnull transitionElement,
                                           BOTransitionInfo transitionInfo,
                                           NSDictionary * _Nullable subInfo) {
                        [transitionElement.transitionView removeFromSuperview];
                    }];
                } else {
                    [bgelement addToStep:BOTransitionStepCancelled
                                   block:^(BOTransitioning * _Nonnull blockTrans,
                                           BOTransitionStep step,
                                           BOTransitionElement * _Nonnull transitionElement,
                                           BOTransitionInfo transitionInfo,
                                           NSDictionary * _Nullable subInfo) {
                        [transitionElement.transitionView removeFromSuperview];
                    }];
                }
                
                [elements addObject:bgelement];
            }
        }
            break;
        default:
            break;
    }
    
}

@end
