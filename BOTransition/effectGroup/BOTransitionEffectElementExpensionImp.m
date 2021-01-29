//
//  BOTransitionEffectElementExpensionImp.m
//  BOTransition
//
//  Created by bo on 2020/11/30.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionEffectElementExpensionImp.h"
#import "BOTransitioning.h"

@implementation BOTransitionEffectElementExpensionImp

- (NSDictionary *)defaultConfigInfo {
    return @{
        @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        @"pinGes": @(NO),
        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
    };
}

- (CGFloat)bo_transitioningDistanceCoefficient:(UISwipeGestureRecognizerDirection)direction {
    switch (direction) {
        case UISwipeGestureRecognizerDirectionUp:
            return 0.84;
        case UISwipeGestureRecognizerDirectionLeft:
            return 1;
        case UISwipeGestureRecognizerDirectionDown:
            return 0.84;
        case UISwipeGestureRecognizerDirectionRight:
            return 1;
        default:
            break;
    }
    return 0;
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
            NSDictionary *configinfo = self.configInfo ? : [self defaultConfigInfo];
            NSNumber *pinGesnum = configinfo[@"pinGes"];
            BOOL pinGes = YES;
            if (nil != pinGesnum && !pinGesnum.boolValue) {
                pinGes = NO;
            }
            
            NSNumber *pinGesElenum = configinfo[@"pinGesEle"];
            BOOL pinGesEle = pinGes;
            if (nil != pinGesElenum) {
                pinGesEle = pinGesElenum.boolValue;
            }
            
            NSNumber *disableBoardMovenum = configinfo[@"disableBoardMove"];
            BOOL disableBoardMove = NO;
            if (nil != disableBoardMovenum && disableBoardMovenum.boolValue) {
                disableBoardMove = YES;
            }
            
            CGRect movedrt;
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                movedrt = [transitioning.transitionContext finalFrameForViewController:transitioning.moveVC];
            } else {
                movedrt = [transitioning.transitionContext initialFrameForViewController:transitioning.moveVC];
            }
            
            UIView *startView = transitioning.moveVCConfig.startViewFromBaseVC;
            CGRect startviewrt = [startView convertRect:startView.bounds toView:container];
            CGRect startrt;
            UIViewContentMode zcm = [configinfo[@"zoomContentMode"] integerValue];
            
            if (startView) {
                switch (zcm) {
                    case UIViewContentModeScaleToFill: {
                        startrt = startviewrt;
                    }
                        break;
                    case UIViewContentModeScaleAspectFit: {
                        
                        startrt = [BOTransitionUtility rectWithAspectFitForBounding:startviewrt size:movedrt.size];
                    }
                        break;
                    case UIViewContentModeScaleAspectFill: {
                        
                        startrt = [BOTransitionUtility rectWithAspectFillForBounding:startviewrt size:movedrt.size];
                    }
                        break;
                    default: {
                        startrt = startviewrt;
                    }
                        break;
                }
                
            } else {
                //没有startView，从baseView的中央弹出
                CGRect baseviewrt = [transitioning.baseVC.view convertRect:transitioning.baseVC.view.bounds
                                                                    toView:container];
                
                CGSize startsz;
                switch (zcm) {
                    case UIViewContentModeScaleToFill: {
                        startsz = CGSizeZero;
                    }
                        break;
                    case UIViewContentModeScaleAspectFit:
                    case UIViewContentModeScaleAspectFill: {
                        startsz = CGSizeMake(10, 10.f * CGRectGetHeight(movedrt) / CGRectGetWidth(movedrt));
                    }
                        break;
                    default: {
                        startsz = CGSizeZero;
                    }
                        break;
                }
                
                startrt = (CGRect){CGRectGetMidX(baseviewrt), CGRectGetMidY(baseviewrt), startsz};
            }
            
            boardelement.transitionView = transitioning.moveVC.view;
            boardelement.frameAllow = !disableBoardMove;
            boardelement.frameShouldPin = pinGes;
            boardelement.frameOrigin = movedrt;
            boardelement.frameBarrierInContainer = UIRectEdgeNone;
            boardelement.alphaAllow = YES;
            //disableBoardMove时突出alpha变化，系数小，有boardmove时突出board移动，系数4初期alpha变化较缓
            boardelement.alphaCalPow = (disableBoardMove ? 2 : 4);
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                boardelement.frameFrom = startrt;
                boardelement.frameTo = movedrt;
                
                boardelement.alphaFrom = 0;
                boardelement.alphaTo = 1;
            } else {
                boardelement.frameFrom = movedrt;
                boardelement.frameTo = startrt;
                
                boardelement.alphaFrom = 1;
                boardelement.alphaTo = 0;
            }
            
            [elements addObject:boardelement];
            
            NSNumber *onlyBoardnum = configinfo[@"onlyBoard"];
            BOOL onlyBoard = NO;
            if (nil != onlyBoardnum && onlyBoardnum.boolValue) {
                onlyBoard = YES;
            }
            
            if (!onlyBoard && startView) {
                UIView *tv = [startView snapshotViewAfterScreenUpdates:NO];
                tv.frame = startviewrt;
                if (!tv) {
                    //                    [startView.layer.copy ]
                }
                
                if (tv) {
                    BOTransitionElement *itemelement = [BOTransitionElement new];
                    itemelement.transitionView = tv;
                    itemelement.frameAllow = YES;
                    itemelement.frameShouldPin = pinGesEle;
                    itemelement.frameAnimationWithTransform = NO;
                    itemelement.frameBarrierInContainer = UIRectEdgeNone;
                    itemelement.alphaAllow = YES;
                    itemelement.alphaCalPow = 4;
                    if (BOTransitionActMoveIn == transitioning.transitionAct) {
                        itemelement.frameOrigin = startviewrt;
                        itemelement.frameFrom = startviewrt;
                        
                        itemelement.frameTo = [BOTransitionUtility rectWithAspectFitForBounding:movedrt size:startviewrt.size];
                        
                        itemelement.alphaFrom = 1;
                        itemelement.alphaTo = 0;
                        
                        itemelement.fromView = startView;
                    } else {
                        itemelement.frameOrigin = startviewrt;
                        
                        itemelement.frameFrom = [BOTransitionUtility rectWithAspectFitForBounding:movedrt size:startviewrt.size];
                        itemelement.frameTo = startviewrt;
                        
                        itemelement.alphaFrom = 0;
                        itemelement.alphaTo = 1;
                        
                        itemelement.toView = startView;
                    }
                    
                    [itemelement addToStep:BOTransitionStepInstallElements
                                     block:^(BOTransitioning * _Nonnull blockTrans,
                                             BOTransitionStep step,
                                             BOTransitionElement * _Nonnull transitionElement,
                                             BOTransitionInfo transitionInfo,
                                             NSDictionary * _Nullable subInfo) {
                        UIView *blockcontainer = blockTrans.transitionContext.containerView;
                        transitionElement.transitionView.frame = startviewrt;
                        [blockcontainer addSubview:transitionElement.transitionView];
                    }];
                    [itemelement addToStep:BOTransitionStepCancelled
                                     block:^(BOTransitioning * _Nonnull blockTrans,
                                             BOTransitionStep step,
                                             BOTransitionElement * _Nonnull transitionElement,
                                             BOTransitionInfo transitionInfo,
                                             NSDictionary * _Nullable subInfo) {
                        [transitionElement.transitionView removeFromSuperview];
                    }];
                    [itemelement addToStep:BOTransitionStepCompleted
                                     block:^(BOTransitioning * _Nonnull blockTrans,
                                             BOTransitionStep step,
                                             BOTransitionElement * _Nonnull transitionElement,
                                             BOTransitionInfo transitionInfo,
                                             NSDictionary * _Nullable subInfo) {
                        [transitionElement.transitionView removeFromSuperview];
                    }];
                    
                    [elements addObject:itemelement];
                }
                
            }
            
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
                bgelement.alphaOrigin = 1;
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
                    [blockcontainer insertSubview:transitionElement.transitionView belowSubview:transitioning.moveVC.view];
                }];
                if (BOTransitionActMoveOut == transitioning.transitionAct) {
                    [bgelement addToStep:BOTransitionStepCompleted
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
