//
//  BOTransitionEffectPhotoPreviewImp.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/3.
//

#import "BOTransitionEffectPhotoPreviewImp.h"
#import "BOTransitionEffectFadeImp.h"
#import "BOTransitioning.h"
#import "UIViewController+BOTransition.h"

@interface BOTransitionEffectPhotoPreviewImp () <BOTransitionEffectControl>

@property (nonatomic, strong) BOTransitionEffectFadeImp *fadeImp;

@end

@implementation BOTransitionEffectPhotoPreviewImp

- (BOTransitionEffectFadeImp *)fadeImp {
    if (!_fadeImp) {
        _fadeImp = [BOTransitionEffectFadeImp new];
        _fadeImp.configInfo = @{
            @"alphaCalPow": @(1.4)
        };
    }
    return _fadeImp;
}

- (NSNumber *)bo_transitioningGetPercent:(BOTransitioning *)transitioning gesture:(BOTransitionGesture *)gesture {
    NSNumber *pinGesnum = self.configInfo[@"freePinGes"];
    if (nil == pinGesnum || !pinGesnum.boolValue) {
        return nil;
    }
    
    CGPoint bgpt = gesture.gesBeganInfo.location;
    CGPoint currpt = gesture.panInfoAr.lastObject.CGRectValue.origin;
    CGFloat dist = pow(pow((currpt.x - bgpt.x), 2.0) + pow((currpt.y - bgpt.y), 2.0), 0.5);
    CGFloat totallen = (gesture.view.bounds.size.height / 2.0) * 1.4;
    CGFloat percent = dist / totallen;
    
    return @(percent);
}

- (NSNumber *)bo_transitioning:(BOTransitioning *)transitioning
     distanceCoefficientForGes:(BOTransitionGesture *)gesture {
    UIView *fromview = transitioning.moveVCConfig.startViewFromBaseVC;
    if (fromview
        && fromview.frame.size.width > transitioning.transitionContext.containerView.frame.size.width - 30) {
        return nil;
    } else {
        return @(0.6);
    }
}

- (nullable NSValue *)bo_transitioning:(BOTransitioning *)transitioning
                  controlCalculateSize:(BOTransitionGesture *)gesture {
    UIView *fromview = transitioning.moveVCConfig.startViewFromBaseVC;
    if (fromview
        && fromview.frame.size.width > transitioning.transitionContext.containerView.frame.size.width - 30) {
        return @(CGSizeMake(60, 60));
    } else {
        return @(0.6);
    }
}

- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements
                 subInfo:(nullable NSDictionary *)subInfo {
    [self.fadeImp bo_transitioning:transitioning
                    prepareForStep:step
                    transitionInfo:transitionInfo
                          elements:elements
                           subInfo:subInfo];
    
    id<UIViewControllerContextTransitioning> context = transitioning.transitionContext;
    UIView *container = context.containerView;
    if (!context ||
        !container) {
        return;
    }
    
    switch (step) {
        case BOTransitionStepInstallElements: {
            BOTransitionElement *photoele = [BOTransitionElement elementWithType:BOTransitionElementTypePhotoMirror];
            
            id<BOTransitionEffectControl> basevcdelegate = transitioning.moveVC.bo_transitionConfig.baseVCDelegate;
            if (!basevcdelegate) {
                basevcdelegate = (id)transitioning.baseVC;
            }
            id<BOTransitionEffectControl> movevcdelegate = transitioning.moveVC.bo_transitionConfig.configDelegate;
            if (!movevcdelegate) {
                movevcdelegate = (id)transitioning.moveVC;
            }
            
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                UIView *from_view = transitioning.moveVCConfig.startViewFromBaseVC;
                NSArray<NSDictionary *> *currfromar = nil;
                if (from_view) {
                    currfromar = @[
                        @{
                            @"view": from_view
                        }
                    ];
                }
                
                if (basevcdelegate
                    && [basevcdelegate respondsToSelector:@selector(bo_transitioningGetTransViewAr:fromViewAr:subInfo:)]) {
                    currfromar = [basevcdelegate bo_transitioningGetTransViewAr:transitioning
                                                                     fromViewAr:currfromar
                                                                        subInfo:nil];
                }
                
                NSArray<NSDictionary *> *currtoar = nil;
                if (movevcdelegate
                    && [movevcdelegate respondsToSelector:@selector(bo_transitioningGetTransViewAr:fromViewAr:subInfo:)]) {
                    currtoar = [movevcdelegate bo_transitioningGetTransViewAr:transitioning
                                                                   fromViewAr:currfromar
                                                                      subInfo:nil];
                }
                
                if (currfromar.count > 0) {
                    photoele.fromView = [currfromar[0] objectForKey:@"view"];
                }
                
                if (currtoar.count > 0) {
                    NSDictionary *configdic = currtoar[0];
                    photoele.toView = [configdic objectForKey:@"view"];
                    photoele.toFrameCoordinateInVC = [configdic objectForKey:@"frame"];
                    photoele.toFrameContentMode = [configdic objectForKey:@"contentMode"];
                }
            } else {
                NSArray<NSDictionary *> *currfromar = nil;
                if (movevcdelegate
                    && [movevcdelegate respondsToSelector:@selector(bo_transitioningGetTransViewAr:fromViewAr:subInfo:)]) {
                    currfromar = [movevcdelegate bo_transitioningGetTransViewAr:transitioning
                                                                     fromViewAr:nil
                                                                        subInfo:nil];
                }
                
                NSArray<NSDictionary *> *currtoar = nil;
                UIView *to_view = transitioning.moveVCConfig.startViewFromBaseVC;
                if (to_view) {
                    currtoar = @[
                        @{
                            @"view": to_view
                        }
                    ];
                }
                if (basevcdelegate
                    && [basevcdelegate respondsToSelector:@selector(bo_transitioningGetTransViewAr:fromViewAr:subInfo:)]) {
                    NSArray<NSDictionary *> *i_toar = nil;
                    i_toar = [basevcdelegate bo_transitioningGetTransViewAr:transitioning
                                                                 fromViewAr:currfromar
                                                                    subInfo:nil];
                    if (nil != i_toar) {
                        currtoar = i_toar;
                    }
                }
                
                if (currfromar.count > 0) {
                    photoele.fromView = [currfromar[0] objectForKey:@"view"];
                }
                
                if (currtoar.count > 0) {
                    NSDictionary *configdic = currtoar[0];
                    photoele.toView = [configdic objectForKey:@"view"];
                    photoele.toFrameCoordinateInVC = [configdic objectForKey:@"frame"];
                    photoele.toFrameContentMode = [configdic objectForKey:@"contentMode"];
                }
            }
            
            [elements addObject:photoele];
        }
            break;
        case BOTransitionStepAfterInstallElements: {
            __block BOTransitionElement *photoele;
            [elements enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (BOTransitionElementTypePhotoMirror == obj.elementType) {
                    photoele = obj;
                }
            }];
            
            UIViewContentMode fromMode = UIViewContentModeScaleAspectFit;
            UIViewContentMode toMode = UIViewContentModeScaleAspectFit;
            
            //fromView需得在屏幕上才层计算位置执行转场
            if (!photoele.fromView
                || nil == photoele.fromView.window
                || (!photoele.toView
                    && !photoele.toFrameCoordinateInVC)) {
                //没有转场View，取消吧
                [elements removeObject:photoele];
                return;
            }
            
            if (photoele.toView
                && [photoele.toView isKindOfClass:[UIImageView class]]) {
                UIImageView *toimgv = (id)photoele.toView;
                toMode = toimgv.contentMode;
            } else if (nil != photoele.toFrameContentMode) {
                toMode = photoele.toFrameContentMode.integerValue;
            }
            
            UIView *tranview;
            /*
             
             */
            BOOL tryUseOriginImage = YES;
            BOOL isoriginimage = NO;
            UIImage *originimage = nil;
            if ([photoele.fromView isKindOfClass:[UIImageView class]]) {
                UIImageView *fromimgv = (id)photoele.fromView;
                fromMode = fromimgv.contentMode;
                
                if (tryUseOriginImage
                    && nil != fromimgv.image) {
                    UIImageView *tiv = [UIImageView new];
                    tiv.image = fromimgv.image;
                    tiv.contentMode = fromMode;
                    tranview = tiv;
                    originimage = tiv.image;
                    isoriginimage = YES;
                }
            }
            
            if (!tranview) {
                tranview = [photoele.fromView snapshotViewAfterScreenUpdates:NO];
            }
            
            if (!tranview) {
                //没截图成功，取消吧
                return;
            }
            
            CGRect fromrt = [photoele.fromView convertRect:photoele.fromView.bounds
                                                    toView:container];
            CGRect tort;
            if (photoele.toFrameCoordinateInVC) {
                UIViewController *tovc;
                if (BOTransitionActMoveIn == transitioning.transitionAct) {
                    tovc = transitioning.moveVC;
                } else {
                    tovc = transitioning.baseVC;
                }
                tort = [tovc.view convertRect:photoele.toFrameCoordinateInVC.CGRectValue
                                       toView:container];
            } else {
                tort = [photoele.toView convertRect:photoele.toView.bounds
                                             toView:container];
            }
            CGRect utort = tort;
            BOOL contentmodeconvert = NO;
            if (isoriginimage
                && fromMode != toMode) {
                switch (fromMode) {
                    case UIViewContentModeScaleAspectFit: {
                        switch (toMode) {
                            case UIViewContentModeScaleAspectFill: {
                                contentmodeconvert = YES;
                                utort = [BOTransitionUtility rectWithAspectFillForBounding:tort size:originimage.size];
                            }
                                break;
                            default:
                                break;
                        }
                    }
                        break;
                    case UIViewContentModeScaleAspectFill: {
                        switch (toMode) {
                            case UIViewContentModeScaleAspectFit: {
                                contentmodeconvert = YES;
                                utort = [BOTransitionUtility rectWithAspectFitForBounding:tort size:originimage.size];
                            }
                                break;
                            default:
                                break;
                        }
                    }
                        break;
                    default:
                        break;
                }
                
                
            }
            
            NSNumber *pinGesnum = self.configInfo[@"pinGes"];
            BOOL pinGes = YES;
            if (nil != pinGesnum && !pinGesnum.boolValue) {
                pinGes = NO;
            }
            
            if (pinGes) {
                NSNumber *disablePinGesForDirectionnum = self.configInfo[@"disablePinGesForDirection"];
                NSUInteger disablePinGesForDirection = 0;
                if (nil != disablePinGesForDirectionnum) {
                    disablePinGesForDirection = disablePinGesForDirectionnum.unsignedIntegerValue;
                }
                
                if (transitionInfo.interactive
                    && (disablePinGesForDirection
                        & transitioning.transitionGes.triggerDirectionInfo.mainDirection)) {
                    pinGes = NO;
                }
            }
            
            photoele.frameShouldPin = pinGes;
            photoele.framePinEffect = @"forceZoomIn";
            photoele.frameCalPow = 0.5;
            tranview.frame = fromrt;
            photoele.transitionView = tranview;
            photoele.frameAllow = YES;
            photoele.frameOrigin = fromrt;
            photoele.frameFrom = fromrt;
            photoele.frameTo = utort;
            photoele.frameAnimationWithTransform = NO;
            photoele.framePinch = YES;
            [photoele addToStep:BOTransitionStepAfterInstallElements
                          block:^(BOTransitioning * _Nonnull blockTrans,
                                  BOTransitionStep step,
                                  BOTransitionElement * _Nonnull transitionElement,
                                  BOTransitionInfo transitionInfo,
                                  NSDictionary * _Nullable subInfo) {
                UIView *blockcontainer = blockTrans.transitionContext.containerView;
                [blockcontainer addSubview:transitionElement.transitionView];
            }];
            
            if (!photoele.framePinch) {
                [photoele addToStep:BOTransitionStepInteractiveEnd
                              block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable bksubInfo) {
                    NSNumber *finishnum = bksubInfo[@"finish"];
                    BOOL bkfinish = YES;
                    if (nil != finishnum) {
                        bkfinish = finishnum.boolValue;
                    }
                    
                    if (bkfinish
                        && contentmodeconvert) {
                        
                        UIImageView *tiv = (id)transitionElement.transitionView;
                        if ([tiv isKindOfClass:[UIImageView class]]) {
                            tiv.clipsToBounds = YES;
                            tiv.contentMode = toMode;
                            
                            if (UIViewContentModeScaleAspectFit == fromMode) {
                                tiv.frame = [BOTransitionUtility rectWithAspectFitForBounding:tiv.frame size:tiv.image.size];
                            } else if (UIViewContentModeScaleAspectFill == toMode) {
                                tiv.frame = [BOTransitionUtility rectWithAspectFillForBounding:tiv.frame size:tiv.image.size];
                            }
                            
                            transitionElement.frameTo = tort;
                        }
                        
                    }
                }];
            }
            
            [photoele addToStep:BOTransitionStepFinished | BOTransitionStepCancelled
                          block:^(BOTransitioning * _Nonnull blockTrans,
                                  BOTransitionStep step,
                                  BOTransitionElement * _Nonnull transitionElement,
                                  BOTransitionInfo transitionInfo,
                                  NSDictionary * _Nullable subInfo) {
                [transitionElement.transitionView removeFromSuperview];
            }];
            
        }
            break;
        default:
            break;
    }
    
}

@end
