//
//  BOTransitionEffectElementExpensionImp.m
//  BOTransition
//
//  Created by bo on 2020/11/30.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionEffectElementExpensionImp.h"

@implementation BOTransitionEffectElementExpensionImp

- (NSDictionary *)defaultConfigInfo {
    return @{
        @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        @"pinGes": @(NO),
        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
    };
}

- (NSNumber *)bo_transitioning:(BOTransitioning *)transitioning
     distanceCoefficientForGes:(BOTransitionGesture *)gesture {
    switch (gesture.triggerDirectionInfo.mainDirection) {
        case UISwipeGestureRecognizerDirectionUp:
            return @(0.84);
        case UISwipeGestureRecognizerDirectionLeft:
            return @(1);
        case UISwipeGestureRecognizerDirectionDown:
            return @(0.84);
        case UISwipeGestureRecognizerDirectionRight:
            return @(1);
        default:
            break;
    }
    return nil;
}

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
            
            boardelement.transitionView = transitioning.moveTransBoard;
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
                    [itemelement addToStep:BOTransitionStepFinished | BOTransitionStepCancelled
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


@implementation BOTransitionElement (Effect)

- (void)makeTransitionEffect:(NSDictionary *)userInfo {
    NSString *actstr = [userInfo objectForKey:@"act"];
    if (actstr.length > 0) {
        if ([actstr isEqualToString:@"autoAddToContainer"]) {
            NSInteger hierarchy = 2;
            if ([userInfo objectForKey:@"hierarchy"]) {
                hierarchy = [userInfo[@"hierarchy"] integerValue];
            }
            [self addToStep:BOTransitionStepInstallElements
                      block:^(BOTransitioning * _Nonnull blockTrans,
                              BOTransitionStep step,
                              BOTransitionElement * _Nonnull te,
                              BOTransitionInfo transitionInfo,
                              NSDictionary * _Nullable subInfo) {
                switch (hierarchy) {
                    case 0: {
                        [blockTrans.transitionContext.containerView insertSubview:te.transitionView atIndex:0];
                    }
                        break;
                    case 1: {
                        if (blockTrans.moveTransBoard.superview == blockTrans.transitionContext.containerView) {
                            [blockTrans.transitionContext.containerView insertSubview:te.transitionView belowSubview:blockTrans.moveTransBoard];
                        } else {
                            [blockTrans.transitionContext.containerView addSubview:te.transitionView];
                        }
                    }
                        break;
                    case 2: {
                        [blockTrans.transitionContext.containerView addSubview:te.transitionView];
                    }
                        break;
                    case 4: {
                        [te.fromView.superview addSubview:te.transitionView];
                    }
                        break;
                    default: {
                        [blockTrans.transitionContext.containerView addSubview:te.transitionView];
                    }
                        break;
                }
            }];
            
            [self addToStep:BOTransitionStepFinished | BOTransitionStepCancelled
                      block:^(BOTransitioning * _Nonnull blockTrans,
                              BOTransitionStep step,
                              BOTransitionElement * _Nonnull te,
                              BOTransitionInfo transitionInfo,
                              NSDictionary * _Nullable subInfo) {
                [te.transitionView removeFromSuperview];
            }];
        }
    } else {
        
        [self addToStep:BOTransitionStepInstallElements
                  block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
            if (!transitionElement.fromView
                || !transitionElement.toView) {
                return;
            }
            
            CGFloat alphaCalPow = 1;
            if ([userInfo objectForKey:@"alphaCalPow"]) {
                alphaCalPow = [userInfo[@"alphaCalPow"] floatValue];
            }
            
            UIView *container = transitioning.transitionContext.containerView;
            
            UIView *fromview = transitionElement.fromView;
            UIView *toview = transitionElement.toView;
            CGRect fromviewrt = [fromview convertRect:fromview.bounds toView:container];
            CGRect toviewrt = [toview convertRect:toview.bounds toView:container];
            
            CGRect fromrt = fromviewrt;
            CGRect tort = CGRectZero;
            
            BOTransitionElement *fromele = [BOTransitionElement elementWithType:BOTransitionElementTypeNormal];
            fromele.transitionView = [fromview snapshotViewAfterScreenUpdates:NO];
            fromele.frameAllow = YES;
            fromele.frameShouldPin = NO;
            fromele.frameAnimationWithTransform = NO;
            fromele.frameBarrierInContainer = UIRectEdgeNone;
            fromele.alphaAllow = YES;
            fromele.alphaCalPow = alphaCalPow;
            
            fromele.frameOrigin = fromviewrt;
            fromele.frameFrom = fromrt;
            
            UIViewContentMode zcm = UIViewContentModeScaleAspectFit;
            if ([userInfo objectForKey:@"zoomContentMode"]) {
                zcm = [userInfo[@"zoomContentMode"] integerValue];
            }
            
            switch (zcm) {
                case UIViewContentModeScaleToFill: {
                    tort = toviewrt;
                }
                    break;
                case UIViewContentModeScaleAspectFit: {
                    tort = [BOTransitionUtility rectWithAspectFitForBounding:toviewrt size:fromviewrt.size];
                }
                    break;
                case UIViewContentModeScaleAspectFill: {
                    tort = [BOTransitionUtility rectWithAspectFillForBounding:toviewrt size:fromviewrt.size];
                }
                    break;
                case UIViewContentModeTop: {
                    CGFloat originy = CGRectGetMinY(toviewrt);
                    tort = [BOTransitionUtility rectWithAspectFitForBounding:toviewrt size:fromviewrt.size];
                    tort.origin.y = originy;
                }
                    break;
                default: {
                    tort = toviewrt;
                }
                    break;
            }
            
            fromele.frameTo = tort;
            
            fromele.alphaFrom = 1;
            fromele.alphaTo = 0;
            
            fromele.fromView = fromview;
            fromele.fromViewAutoHidden = YES;
            [fromele makeTransitionEffect:@{
                @"act": @"autoAddToContainer",
                @"hierarchy": [transitionElement.userInfo objectForKey:@"hierarchy"] ? : @(2)
            }];
            
            [transitionElement addSubElement:fromele];
            
            NSInteger tovieweffect = 0;
            if ([userInfo objectForKey:@"toViewEffect"]) {
                tovieweffect = [userInfo[@"toViewEffect"] integerValue];
            }
            
            BOTransitionElement *toele = [BOTransitionElement elementWithType:BOTransitionElementTypeNormal];
            switch (tovieweffect) {
                case 0: {
                    UIView *tts = [toview snapshotViewAfterScreenUpdates:YES];
                    toele.transitionView = tts;
                    toele.frameAllow = YES;
                    [toele makeTransitionEffect:@{@"act": @"autoAddToContainer"}];
                }
                    break;
                case 1: {
                    toele.transitionView = toview;
                    toele.frameAllow = NO;
                }
                    break;
                default:
                    break;
            }
            
            toele.frameShouldPin = NO;
            toele.frameAnimationWithTransform = NO;
            toele.frameBarrierInContainer = UIRectEdgeNone;
            toele.alphaAllow = YES;
            toele.alphaCalPow = alphaCalPow;
            
            toele.frameOrigin = toviewrt;
            toele.frameFrom = fromviewrt;
            
            toele.frameTo = toviewrt;
            
            toele.alphaOrigin = toview.alpha;
            toele.alphaFrom = 0;
            toele.alphaTo = 1;
            
            toele.toView = toview;
            toele.toViewAutoHidden = NO;
            
            [transitionElement addSubElement:toele];
            
        }];
    }
}

@end
