//
//  BOTransitionEffectPhotoPreviewImp.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/3.
//

#import "BOTransitionEffectPhotoPreviewImp.h"
#import "BOTransitionEffectFadeImp.h"
#import "BOTransitioning.h"

@interface BOTransitionEffectPhotoPreviewImp () <BOTransitionEffectControl>

@property (nonatomic, strong) BOTransitionEffectFadeImp *fadeImp;

@end

@implementation BOTransitionEffectPhotoPreviewImp

- (BOTransitionEffectFadeImp *)fadeImp {
    if (!_fadeImp) {
        _fadeImp = [BOTransitionEffectFadeImp new];
    }
    return _fadeImp;
}

- (NSNumber *)bo_transitioning:(BOTransitioning *)transitioning
     distanceCoefficientForGes:(BOTransitionPanGesture *)gesture {
    return @(0.84);
}

- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements {
    [self.fadeImp bo_transitioning:transitioning
                    prepareForStep:step
                    transitionInfo:transitionInfo
                          elements:elements];
    
    id<UIViewControllerContextTransitioning> context = transitioning.transitionContext;
    UIView *container = context.containerView;
    if (!context ||
        !container) {
        return;
    }
    
    switch (step) {
        case BOTransitionStepInstallElements: {
            BOTransitionElement *element = [BOTransitionElement elementWithType:BOTransitionElementTypePhotoMirror];
            [elements addObject:element];
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
            
            if (BOTransitionActMoveIn == transitioning.transitionAct) {
                if (!photoele.fromView) {
                    photoele.fromView = transitioning.moveVCConfig.startViewFromBaseVC;
                }
            } else {
                if (!photoele.toView) {
                    photoele.toView = transitioning.moveVCConfig.startViewFromBaseVC;
                }
            }
            
            if (!photoele.fromView
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
                
                if (tryUseOriginImage) {
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
            tranview.frame = fromrt;
            photoele.transitionView = tranview;
            photoele.frameAllow = YES;
            photoele.frameOrigin = fromrt;
            photoele.frameFrom = fromrt;
            photoele.frameTo = utort;
            photoele.frameAnimationWithTransform = NO;
            
            [photoele addToStep:BOTransitionStepAfterInstallElements
                          block:^(BOTransitioning * _Nonnull blockTrans,
                                  BOTransitionStep step,
                                  BOTransitionElement * _Nonnull transitionElement,
                                  BOTransitionInfo transitionInfo,
                                  NSDictionary * _Nullable subInfo) {
                UIView *blockcontainer = blockTrans.transitionContext.containerView;
                [blockcontainer addSubview:transitionElement.transitionView];
            }];
            
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
