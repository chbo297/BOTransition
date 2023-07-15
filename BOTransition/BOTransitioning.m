//
//  BOTransitioning.m
//  BOTransition
//
//  Created by bo on 2020/7/27.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitioning.h"
#import "UIViewController+BOTransition.h"
#import "BOTransitionNCProxy.h"
#import "BOTransitionUtility.h"

@interface BOTransitionElement ()

@property (nonatomic, strong) NSMutableDictionary *userInfo;

@property (nonatomic, strong, nullable) NSMutableArray<BOTransitionElement *> *subEleAr;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *,
NSMutableArray<void (^)(BOTransitioning *transitioning, BOTransitionStep step,
                        BOTransitionElement *transitionItem, BOTransitionInfo transitionInfo,
                        NSDictionary * _Nullable info)> *> *blockDic;

@end

@implementation BOTransitionElement

+ (instancetype)elementWithType:(BOTransitionElementType)type {
    BOTransitionElement *ele = [BOTransitionElement new];
    ele.elementType = type;
    return ele;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _frameInteractiveLimit = 1;
        _alphaInteractiveLimit = 1;
        _frameAnimationWithTransform = YES;
        _frameCalPow = 1;
        _alphaCalPow = 1;
        _alphaOrigin = 1;
        _fromViewAutoHidden = YES;
        _toViewAutoHidden = YES;
    }
    return self;
}

- (NSMutableDictionary *)userInfo {
    if (!_userInfo) {
        _userInfo = @{}.mutableCopy;
    }
    return _userInfo;;
}

- (void)addSubElement:(BOTransitionElement *)element {
    if (!element) {
        return;
    }
    
    if (!_subEleAr) {
        _subEleAr = @[].mutableCopy;
    }
    element.superElement = self;
    [_subEleAr addObject:element];
}

- (void)removeSubElement:(BOTransitionElement *)element {
    [_subEleAr removeObject:element];
    element.superElement = nil;
    if (_subEleAr) {
        _subEleAr = nil;
    }
}

/*
 优先使用自己的，自己没有则继承super的
 */
- (CGFloat (^)(CGFloat))innerPercentWithTransitionPercent {
    if (_innerPercentWithTransitionPercent) {
        return _innerPercentWithTransitionPercent;
    } else {
        return [self.superElement innerPercentWithTransitionPercent];
    }
}

- (NSMutableDictionary<NSNumber *,NSMutableArray<void (^)(BOTransitioning *,
                                                          BOTransitionStep,
                                                          BOTransitionElement *,
                                                          BOTransitionInfo,
                                                          NSDictionary * _Nullable)> *> *)blockDic {
    if (!_blockDic) {
        _blockDic = [NSMutableDictionary new];
    }
    return _blockDic;
}

- (void)addToStep:(BOTransitionStep)step
            block:(void (^)(BOTransitioning *transitioning,
                            BOTransitionStep step,
                            BOTransitionElement *transitionItem,
                            BOTransitionInfo transitionInfo,
                            NSDictionary * _Nullable subInfo))block {
    NSNumber *key = @(step);
    NSMutableArray<void (^)(BOTransitioning *transitioning,
                            BOTransitionStep,
                            BOTransitionElement * _Nonnull,
                            BOTransitionInfo,
                            NSDictionary * _Nullable)> *blockar =\
    [self.blockDic objectForKey:key];
    
    if (!blockar) {
        blockar = [NSMutableArray new];
        [self.blockDic setObject:blockar forKey:key];
    }
    [blockar addObject:block];
}

- (void)execTransitioning:(BOTransitioning *)transitioning
                     step:(BOTransitionStep)step
           transitionInfo:(BOTransitionInfo)transitionInfo
                  subInfo:(nullable NSDictionary *)subInfo {
    
    NSMutableArray<void (^)(BOTransitioning *transitioning,
                            BOTransitionStep,
                            BOTransitionElement * _Nonnull,
                            BOTransitionInfo,
                            NSDictionary * _Nullable)> *blockar = @[].mutableCopy;
    
    [self.blockDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<void (^)(BOTransitioning *, BOTransitionStep, BOTransitionElement *, BOTransitionInfo, NSDictionary * _Nullable)> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSUInteger stepval = key.unsignedIntegerValue;
        if ((step & stepval)
            && obj.count > 0) {
            [blockar addObjectsFromArray:obj];
        }
    }];
    
    [blockar enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(BOTransitioning *,
                                                                BOTransitionStep,
                                                                BOTransitionElement * _Nonnull,
                                                                BOTransitionInfo,
                                                                NSDictionary * _Nullable),
                                          NSUInteger idx,
                                          BOOL * _Nonnull stop) {
        obj(transitioning, step, self, transitionInfo, subInfo);
    }];
    
    UIView *thetrView = self.transitionView;
    if (thetrView) {
        BOOL ani = NO;
        NSNumber *anival = [subInfo objectForKey:@"ani"];
        if (nil != anival) {
            ani = anival.boolValue;
        }
        if (ani) {
            self.alphaLastBeforeAni = @(thetrView.alpha);
            self.frameLastBeforeAni = @(thetrView.frame);
        }
        
        __weak typeof(self) ws = self;
        switch (step) {
            case BOTransitionStepInstallElements : {
                if (self.autoAddAndRemoveTransitionView > 0
                    && self.transitionView) {
                    UIView *trancontainer = transitioning.transitionContext.containerView;
                    self.transitionView.frame = trancontainer.bounds;
                    if (self.autoAddAndRemoveTransitionView <= 10) {
                        if (transitioning.baseTransBoard
                            && transitioning.baseTransBoard.superview == trancontainer) {
                            [trancontainer insertSubview:self.transitionView belowSubview:transitioning.baseTransBoard];
                        } else {
                            [trancontainer insertSubview:self.transitionView atIndex:0];
                        }
                    } else if (self.autoAddAndRemoveTransitionView <= 20) {
                        if (transitioning.moveTransBoard
                            && transitioning.moveTransBoard.superview == trancontainer) {
                            [trancontainer insertSubview:self.transitionView belowSubview:transitioning.moveTransBoard];
                        } else {
                            [trancontainer addSubview:self.transitionView];
                        }
                    } else if (self.autoAddAndRemoveTransitionView <= 30) {
                        [trancontainer addSubview:self.transitionView];
                    }
                }
            }
                break;
            case BOTransitionStepAfterInstallElements: {
                if (self.fromView &&
                    self.fromViewAutoHidden) {
                    BOOL originfromhidden = self.fromView.hidden;
                    self.fromView.hidden = YES;
                    [self addToStep:BOTransitionStepFinished | BOTransitionStepCancelled
                              block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                        ws.fromView.hidden = originfromhidden;
                    }];
                }
                
                if (self.toView &&
                    self.toViewAutoHidden) {
                    BOOL origintohidden = self.toView.hidden;
                    self.toView.hidden = YES;
                    [self addToStep:BOTransitionStepFinished | BOTransitionStepCancelled
                              block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                        ws.toView.hidden = origintohidden;
                    }];
                }
            }
                break;
            case BOTransitionStepInitialAnimatableProperties: {
                if (self.frameAllow) {
                    if (transitionInfo.interactive) {
                        CGPoint beganPt = transitionInfo.panBeganLoc;
                        CGRect thevrt = self.frameFrom;
                        //防止thevrt为0导致除0
                        if (CGRectIsEmpty(thevrt)) {
                            self.framePinAnchor = CGPointZero;
                        } else {
                            self.framePinAnchor = CGPointMake((beganPt.x - CGRectGetMidX(thevrt)) / CGRectGetWidth(thevrt),
                                                              (beganPt.y - CGRectGetMidY(thevrt)) / CGRectGetHeight(thevrt));
                        }
                    }
                    
                    if (self.frameAnimationWithTransform) {
                        thetrView.transform = CGAffineTransformIdentity;
                        thetrView.frame = self.frameOrigin;
                        if (CGRectEqualToRect(self.frameFrom, self.frameOrigin)) {
                            thetrView.transform = CGAffineTransformIdentity;
                        } else {
                            thetrView.transform = [BOTransitionUtility getTransform:self.frameOrigin to:self.frameFrom];
                        }
                    } else {
                        thetrView.frame = self.frameFrom;
                    }
                }
                
                if (self.alphaAllow) {
                    thetrView.alpha = self.alphaFrom;
                }
            }
                break;
            case BOTransitionStepTransitioning: {
                CGFloat percentComplete = transitionInfo.percentComplete;
                if (self.innerPercentWithTransitionPercent) {
                    percentComplete = self.innerPercentWithTransitionPercent(percentComplete);
                }
                if (self.frameAllow) {
                    CGRect rtorigin = self.frameOrigin;
                    CGRect rtto = self.frameTo;
                    CGRect rtfrom = self.frameFrom;
                    CGFloat upc = pow(percentComplete, self.frameCalPow);
                    CGFloat scalepercent = (transitionInfo.interactive ?
                                            MIN(self.frameInteractiveLimit, upc)
                                            :
                                            upc);
                    
                    CGSize tsz =\
                    CGSizeMake([BOTransitionUtility lerpV0:CGRectGetWidth(rtfrom)
                                                        v1:CGRectGetWidth(rtto) t:scalepercent],
                               [BOTransitionUtility lerpV0:CGRectGetHeight(rtfrom)
                                                        v1:CGRectGetHeight(rtto) t:scalepercent]);
                    
                    CGPoint tocenter;
                    CGRect currt;
                    if (self.frameShouldPin && transitionInfo.interactive) {
                        tocenter =\
                        CGPointMake(transitionInfo.panCurrLoc.x - tsz.width * self.framePinAnchor.x,
                                    transitionInfo.panCurrLoc.y - tsz.height * self.framePinAnchor.y);
                        currt = (CGRect){tocenter.x - tsz.width / 2.f, tocenter.y - tsz.height / 2.f, tsz};
                        if (self.frameBarrierInContainer > 0) {
                            CGRect containerbounds = thetrView.superview.bounds;
                            CGFloat topext = CGRectGetMinY(containerbounds) - CGRectGetMinY(currt);
                            CGFloat downext = CGRectGetMaxY(currt) - CGRectGetMaxY(containerbounds);
                            CGPoint offset = CGPointZero;
                            if (topext > 0
                                && (UIRectEdgeTop & self.frameBarrierInContainer)) {
                                if (downext > 0) {
                                    NSLog(@"error:%s ~~~1", __func__);
                                } else {
                                    offset.y = topext;
                                }
                            } else {
                                if (downext > 0
                                    && (UIRectEdgeBottom & self.frameBarrierInContainer)) {
                                    offset.y = -downext;
                                } else {
                                    //mei wenti
                                }
                            }
                            
                            CGFloat leftext = CGRectGetMinX(containerbounds) - CGRectGetMinX(currt);
                            CGFloat rightext = CGRectGetMaxX(currt) - CGRectGetMaxX(containerbounds);
                            if (leftext > 0
                                && (UIRectEdgeLeft & self.frameBarrierInContainer)) {
                                if (rightext > 0) {
                                    NSLog(@"error:%s ~~~2", __func__);
                                } else {
                                    offset.x = leftext;
                                }
                            } else {
                                if (rightext > 0
                                    && (UIRectEdgeRight & self.frameBarrierInContainer)) {
                                    offset.x = -rightext;
                                } else {
                                    //mei wenti
                                }
                            }
                            
                            currt.origin.x += offset.x;
                            currt.origin.y += offset.y;
                            
                            self.framePinAnchor =\
                            CGPointMake((transitionInfo.panCurrLoc.x - CGRectGetMidX(currt)) / CGRectGetWidth(currt),
                                        (transitionInfo.panCurrLoc.y - CGRectGetMidY(currt)) / CGRectGetHeight(currt));
                        }
                        
                    } else {
                        tocenter =\
                        CGPointMake([BOTransitionUtility lerpV0:CGRectGetMidX(rtfrom)
                                                             v1:CGRectGetMidX(rtto) t:percentComplete],
                                    [BOTransitionUtility lerpV0:CGRectGetMidY(rtfrom)
                                                             v1:CGRectGetMidY(rtto) t:percentComplete]);
                        currt = (CGRect){tocenter.x - tsz.width / 2.f, tocenter.y - tsz.height / 2.f, tsz};
                    }
                    
                    if (self.frameAnimationWithTransform) {
                        thetrView.transform = [BOTransitionUtility getTransform:rtorigin to:currt];
                    } else {
                        thetrView.frame = currt;
                    }
                    
                }
                
                if (self.alphaAllow) {
                    CGFloat upc = pow(percentComplete, self.alphaCalPow);
                    
                    CGFloat curalpha = [BOTransitionUtility lerpV0:self.alphaFrom
                                                                v1:self.alphaTo
                                                                 t:(transitionInfo.interactive ?
                                                                    MIN(self.alphaInteractiveLimit, upc)
                                                                    :
                                                                    upc)];
                    thetrView.alpha = curalpha;
                }
            }
                break;
            case BOTransitionStepFinalAnimatableProperties: {
                if (self.frameAllow) {
                    if (self.frameAnimationWithTransform) {
                        
                        if (CGRectEqualToRect(self.frameOrigin, self.frameTo)) {
                            thetrView.transform = CGAffineTransformIdentity;
                        } else {
                            thetrView.transform = [BOTransitionUtility getTransform:self.frameOrigin to:self.frameTo];
                        }
                    } else {
                        thetrView.frame = self.frameTo;
                    }
                }
                
                if (self.alphaAllow) {
                    thetrView.alpha = self.alphaTo;
                }
            }
                break;
                
            case BOTransitionStepCancelled:
            case BOTransitionStepFinished: {
                if (self.frameAllow && !self.frameAnimationWithTransform) {
                    thetrView.frame = self.frameOrigin;
                }
                if (self.alphaAllow) {
                    thetrView.alpha = self.alphaOrigin;
                }
                
                if (self.autoAddAndRemoveTransitionView > 0
                    && self.transitionView) {
                    if (self.transitionView.superview == transitioning.transitionContext.containerView) {
                        [self.transitionView removeFromSuperview];
                    }
                }
            }
                break;
            default:
                break;
        }
    }
    
    [self.subEleAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:transitioning
                          step:step
                transitionInfo:transitionInfo
                       subInfo:subInfo];
    }];
}

- (CGFloat)interruptAnimation:(BOTransitionInfo)transitionInfo {
    CALayer *displaylayer =\
    (self.transitionView.layer.presentationLayer ? : self.transitionView.layer);
    
    if (self.alphaAllow) {
        self.transitionView.alpha = displaylayer.opacity;
    }
    
    if (self.frameAllow) {
        if (self.frameAnimationWithTransform) {
            self.transitionView.transform = [BOTransitionUtility getTransform:self.frameOrigin
                                                                           to:displaylayer.frame];
        } else {
            self.transitionView.frame = displaylayer.frame;
        }
        
    }
    
    [self.subEleAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj interruptAnimation:transitionInfo];
    }];
    
    return -1;
}

- (void)interruptAnimationAndResetPorperty:(BOTransitioning *)transitioning
                            transitionInfo:(BOTransitionInfo)transitionInfo
                                   subInfo:(nullable NSDictionary *)subInfo {
    
    UIView *thetrView = self.transitionView;
    if (!thetrView) {
        return;
    }
    
    [thetrView.layer removeAllAnimations];
    CGFloat percentComplete = transitionInfo.percentComplete;
    CGFloat anipercent;
    NSNumber *anipercentval = [subInfo objectForKey:@"aniPercent"];
    if (nil != anipercentval) {
        anipercent = anipercentval.floatValue;
    } else {
        //容错，不应发生
        anipercent = 0.5;
    }
    
    if (self.frameAllow) {
        if (nil != self.frameLastBeforeAni) {
            CGRect anifrom = self.frameLastBeforeAni.CGRectValue;
            CGRect anito = thetrView.frame;
            
            CGPoint currcenter =\
            CGPointMake([BOTransitionUtility lerpV0:CGRectGetMidX(anifrom) v1:CGRectGetMidX(anito) t:anipercent],
                        [BOTransitionUtility lerpV0:CGRectGetMidY(anifrom) v1:CGRectGetMidY(anito) t:anipercent]);
            
            CGSize currsz =\
            CGSizeMake([BOTransitionUtility lerpV0:CGRectGetWidth(anifrom) v1:CGRectGetWidth(anito) t:anipercent],
                       [BOTransitionUtility lerpV0:CGRectGetHeight(anifrom) v1:CGRectGetHeight(anito) t:anipercent]);
            
            CGRect currrt = (CGRect){currcenter.x - currsz.width / 2.f,
                currcenter.y - currsz.height / 2.f,
                currsz};
            
            self.framePinAnchor =\
            CGPointMake((transitionInfo.panCurrLoc.x - CGRectGetMidX(currrt)) / CGRectGetWidth(currrt),
                        (transitionInfo.panCurrLoc.y - CGRectGetMidY(currrt)) / CGRectGetHeight(currrt));
            if (self.frameAnimationWithTransform) {
                thetrView.transform = [BOTransitionUtility getTransform:self.frameOrigin to:currrt];
            } else {
                thetrView.frame = currrt;
            }
            
        } else {
            //容错，不应发生
        }
    }
    
    if (self.alphaAllow) {
        if (nil != self.alphaLastBeforeAni) {
            thetrView.alpha = [BOTransitionUtility lerpV0:self.alphaLastBeforeAni.floatValue
                                                       v1:thetrView.alpha t:pow(anipercent, self.alphaCalPow)];
        } else {
            //容错，不应发生
            CGFloat curalpha = [BOTransitionUtility lerpV0:self.alphaFrom
                                                        v1:self.alphaTo t:pow(percentComplete, self.alphaCalPow)];
            thetrView.alpha = curalpha;
        }
        
    }
    
    [self.subEleAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj interruptAnimationAndResetPorperty:transitioning
                                 transitionInfo:transitionInfo
                                        subInfo:subInfo];
    }];
}

@end


const NSNotificationName BOTransitionVCViewDidMoveToContainer =\
@"BOTransitionVCViewDidMoveToContainer";

const NSNotificationName BOTransitionWillAndMustCompletion =\
@"BOTransitionWillAndMustCompletion";

static CGFloat sf_default_transition_dur = 0.22f;

@interface BOTransitioning () <BOTransitionGestureDelegate>

@property (nonatomic, assign) BOTransitionType transitionType;

//present/push动作发生之前前已经在展示的基准VC
@property (nonatomic, strong) UIViewController *baseVC;

//present/push动作的入场VC以及 dismiss/pop动作的离场VC
@property (nonatomic, strong) UIViewController *moveVC;

@property (nonatomic, strong) UIView *baseTransBoard;
@property (nonatomic, strong) UIView *moveTransBoard;

@property (nonatomic, assign) BOOL isBaseTransBoardCustom;
@property (nonatomic, assign) BOOL isMoveTransBoardCustom;

@property (nonatomic, assign) BOOL hasAddBaseWhenInitialViewHierarchy;
@property (nonatomic, assign) BOOL hasAddMoveWhenInitialViewHierarchy;

@property (nonatomic, strong) UIView *commonBg;

@property (nonatomic, strong) BOTransitionPanGesture *transitionGes;

@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic, assign) BOOL triggerInteractiveTransitioning;

@property (nonatomic, strong) NSArray<id<BOTransitionEffectControl>> *effectControlAr;

@property (nonatomic, strong) NSMutableArray<BOTransitionElement *> *transitionElementAr;

@property (nonatomic, strong) NSValue *innerAnimatingVal;

//时间刻度
@property (nonatomic, strong) UIView *timeRuler;

@property (nonatomic, assign) BOOL shouldRunAniCompletionBlock;

@property (nonatomic, assign) BOOL startWithInteractive;

@end

@implementation BOTransitioning

+ (instancetype)transitioningWithType:(BOTransitionType)transitionType {
    BOTransitioning *transitioning = [[BOTransitioning alloc] initWithTransitionType:transitionType];
    return transitioning;
}

- (instancetype)initWithTransitionType:(BOTransitionType)transitionType {
    self = [super init];
    if (self) {
        _transitionType = transitionType;
    }
    return self;
}

- (BOTransitionPanGesture *)transitionGes {
    if (!_transitionGes) {
        _transitionGes = [[BOTransitionPanGesture alloc] initWithTransitionGesDelegate:self];
    }
    return _transitionGes;
}

- (UIViewController *)startVC {
    switch (self.transitionAct) {
        case BOTransitionActMoveIn:
            return self.baseVC;
        case BOTransitionActMoveOut:
            return self.moveVC;
        default:
            return nil;
    }
}

- (UIViewController *)desVC {
    switch (self.transitionAct) {
        case BOTransitionActMoveIn:
            return self.moveVC;
        case BOTransitionActMoveOut:
            return self.baseVC;
        default:
            return nil;
    }
}

- (void)setMoveVC:(UIViewController *)moveVC {
    _moveVC = moveVC;
    _moveVCConfig = _moveVC.bo_transitionConfig;
}

- (BOOL)setupTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext
                   interactive:(BOOL)interactive {
    _startWithInteractive = interactive;
    if (!transitionContext
        || BOTransitionTypeNone == _transitionType
        || BOTransitionActNone == _transitionAct) {
        return NO;
    }
    
    _transitionContext = transitionContext;
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (BOTransitionActMoveIn == self.transitionAct) {
        self.baseVC = fromVC;
        self.moveVC = toVC;
    } else {
        self.baseVC = toVC;
        self.moveVC = fromVC;
    }
    
    if (!self.moveVC) {
        return NO;
    }
    
    if (BOTransitionTypeModalPresentation == self.transitionType &&
        BOTransitionActMoveIn == self.transitionAct) {
        //初始化手势
        UIView *container = [transitionContext containerView];
        if (container) {
            if (![container.gestureRecognizers containsObject:self.transitionGes]) {
                [container addGestureRecognizer:self.transitionGes];
            }
        }
    }
    
    return YES;
}

- (void)loadEffectControlAr:(BOOL)interactive {
    NSMutableArray<id<BOTransitionEffectControl>> *controlar = [NSMutableArray new];
    
    //Navigation是，对应时机告知transitionNCHandler
    if (BOTransitionTypeNavigation == self.transitionType) {
        id<BOTransitionEffectControl> nchandler = self.navigationController.bo_transProxy.transitionEffectControl;
        if (nil != nchandler) {
            [controlar addObject:nchandler];
        }
    }
    
    NSDictionary *effectconfig;
    
    if (interactive) {
        NSDictionary *triggerGesInfo = [self.transitionGes.userInfo objectForKey:@"triggerGesInfo"];
        if ([triggerGesInfo isKindOfClass:[NSDictionary class]]
            && triggerGesInfo.count > 0) {
            NSDictionary *econfig = [triggerGesInfo objectForKey:@"effectConfig"];
            if ([econfig isKindOfClass:[econfig class]]) {
                effectconfig = econfig;
            }
        }
    }
    
    if (!effectconfig) {
        if (BOTransitionActMoveIn == self.transitionAct) {
            effectconfig = self.moveVCConfig.moveInEffectConfig;
        } else {
            if (interactive) {
                effectconfig = (self.moveVCConfig.moveOutEffectConfigForInteractive.count > 0 ?
                                self.moveVCConfig.moveOutEffectConfigForInteractive
                                :
                                self.moveVCConfig.moveOutEffectConfig);
            } else {
                effectconfig = self.moveVCConfig.moveOutEffectConfig;
            }
        }
    }
    
    if (effectconfig.count > 0) {
        NSString *effectstyle = effectconfig[@"style"];
        if (effectstyle.length > 0) {
            NSString *impclass = [NSString stringWithFormat:@"BOTransitionEffect%@Imp", effectstyle];
            Class impcls = NSClassFromString(impclass);
            if (impcls) {
                id<BOTransitionEffectControl> econtrol = [[impcls alloc] init];
                if ([econtrol respondsToSelector:@selector(setConfigInfo:)]) {
                    [econtrol setConfigInfo:effectconfig[@"config"]];
                }
                [controlar addObject:econtrol];
            }
        }
    }
    
    id<BOTransitionEffectControl> baseVCDelegate = self.moveVCConfig.baseVCDelegate;
    if (!baseVCDelegate) {
        //可以不判断protocol，允许使用者不声明protocol只实现方法
        baseVCDelegate = (id)self.baseVC;
    }
    
    id<BOTransitionConfigDelegate> configDelegate = self.moveVCConfig.configDelegate;
    if (!configDelegate) {
        configDelegate = (id)self.moveVC;
    }
    
    if (BOTransitionActMoveIn == self.transitionAct) {
        //moveIn时，先加base再加moved，因为执行顺序是从前往后，moveIn最终效果以moved为准
        if (baseVCDelegate) {
            [controlar addObject:baseVCDelegate];
        }
        
        if (configDelegate) {
            [controlar addObject:configDelegate];
        }
    } else {
        //moveOut时，先加moved再加base
        if (configDelegate) {
            [controlar addObject:configDelegate];
        }
        
        if (baseVCDelegate) {
            [controlar addObject:baseVCDelegate];
        }
    }
    
    if (controlar.count) {
        self.effectControlAr = controlar;
    } else {
        self.effectControlAr = nil;
    }
}

- (void)makePrepareAndExecStep:(BOTransitionStep)step
                      elements:(nullable NSMutableArray<BOTransitionElement *> *)elements
                transitionInfo:(BOTransitionInfo)transitioninfo
                       subInfo:(nullable NSDictionary *)subInfo {
    
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:step
                   transitionInfo:transitioninfo
                         elements:elements];
        }
    }];
    
    [elements enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:step
                transitionInfo:transitioninfo
                       subInfo:subInfo];
    }];
}

- (UIView *)timeRuler {
    if (!_timeRuler) {
        _timeRuler = [[UIView alloc] initWithFrame:CGRectZero];
        _timeRuler.userInteractionEnabled = NO;
        _timeRuler.backgroundColor = [UIColor clearColor];
    }
    return _timeRuler;
}

- (UIView *)checkAndInitCommonBg {
    if (!_commonBg) {
        _commonBg = [UIView new];
        _commonBg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.27];
        _commonBg.userInteractionEnabled = NO;
        _commonBg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _commonBg;
}

#pragma mark - AnimatedTransitioning
- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return sf_default_transition_dur;
}

- (UIView *)obtainTransBoardForVC:(BOOL)baseYESorMoveNO isCreate:(BOOL *)isCreate {
    UIViewController *vc = baseYESorMoveNO ? self.baseVC : self.moveVC;
    
    if (!vc) {
        if (isCreate) {
            *isCreate = NO;
        }
        return nil;
    }
    
    UIView *retview = vc.view;
    BOOL retiscreate = NO;
    
    if (BOTransitionTypeNavigation == _transitionType
        && vc.presentedViewController
        && [vc.presentedViewController viewIfLoaded]) {
        UIView *tcontainer = self.transitionContext.containerView;
        UIView *vcsuperview = vc.view.superview;
        UIView *pretransv = vc.presentedViewController.view.superview;
        if (pretransv) {
            UIView *prevcsuperview = pretransv.superview;
            if (!vcsuperview
                || !prevcsuperview) {
                //都没有在图层(或者有一个有图层--用来容错)，可以放在一起
                UIView *board = [[UIView alloc] initWithFrame:tcontainer.bounds];
                [board addSubview:vc.view];
                [board addSubview:pretransv];
                if (vcsuperview) {
                    [vcsuperview addSubview:board];
                }
                retiscreate = YES;
                retview = board;
            } else if (vcsuperview
                       && prevcsuperview
                       && vcsuperview == prevcsuperview) {
                if (vcsuperview == tcontainer) {
                    //已经是总容器了，再添加一个board用来转场
                    UIView *board = [[UIView alloc] initWithFrame:tcontainer.bounds];
                    [board addSubview:vc.view];
                    [board addSubview:pretransv];
                    [vcsuperview addSubview:board];
                    retiscreate = YES;
                    retview = board;
                } else if (nil == vcsuperview.superview
                           || vcsuperview.superview == tcontainer
                           || vcsuperview.superview.superview == tcontainer) {
                    //不在图层中，或已经是总容器的子视图了
                    retiscreate = NO;
                    
                    /*
                     系统的navigation先push一个vcA，该vcA再用over方式present一个vcB
                     此时手势返回vcA，中途取消，系统自己的navigation的UIViewControllerWrapperView容器居然错乱了，
                     导致：（UI展示倒是正常，但是图层冗余了，有好多层WrapperView）
                     分析是由于apple没有处理好在pop过程中自动生成的vcA和vcB的共同容器，自动创建了，但没自动销毁，
                     导致navigation重新计算vcA的图层位置时，创建了新的WrapperView来承载。就会每操作一次重复创建一个WrapperView
                     这里识别这种情况，把该vcA和vcB的共同容器定义为custom（自创建类型，接管其移除行为），帮助系统移除该view
                     效果上看，用该方式可修复此问题。
                     */
                    if (!baseYESorMoveNO) {
                        //暂不介入系统地这个bug
//                        retiscreate = YES;
                    }
                    
                    retview = vcsuperview;
                }
            }
        }
    }
    
    CGRect vcrt = [_transitionContext finalFrameForViewController:vc];
    if (!CGRectIsEmpty(vcrt)
        && CGRectEqualToRect(retview.frame, vcrt)) {
        //容器使用finalFrame
        retview.frame = vcrt;
    }
    
    if (vc.view != retview) {
        //若有容器，内部的origin为0即可
        vcrt.origin = CGPointZero;
        if (!CGRectIsEmpty(vcrt)
            && CGRectEqualToRect(vc.view.frame, vcrt)) {
            vc.view.frame = vcrt;
        }
    }
    
    if (isCreate) {
        *isCreate = retiscreate;
    }
    
    return retview;
}

- (void)removeViewFromSuperAndRecoverSub:(UIView *)theView {
    if (!theView) {
        return;
    }
    
    UIView *thesuperview = theView.superview;
    CGPoint boardorigin = theView.frame.origin;
    
    __block NSInteger locidx = NSNotFound;
    if (thesuperview) {
        locidx = [thesuperview.subviews indexOfObject:theView];
        [theView removeFromSuperview];
    }
    
    NSArray<UIView *> *subviews = theView.subviews;
    for (UIView *obj in subviews) {
        [obj removeFromSuperview];
        
        if (boardorigin.x != 0
            || boardorigin.y != 0) {
            CGRect objrt = obj.frame;
            objrt.origin.x += boardorigin.x;
            objrt.origin.y += boardorigin.y;
            obj.frame = objrt;
        }
        
        if (NSNotFound != locidx
            && thesuperview) {
            [thesuperview insertSubview:obj atIndex:locidx];
            locidx++;
        }
    }
}

- (void)removeCustomTransBoard {
    if (self.isBaseTransBoardCustom) {
        [self removeViewFromSuperAndRecoverSub:self.baseTransBoard];
        
        self.baseTransBoard = nil;
    }
    
    if (self.isMoveTransBoardCustom) {
        [self removeViewFromSuperAndRecoverSub:self.moveTransBoard];
        self.moveTransBoard = nil;
    }
}

- (void)initialViewHierarchy {
    UIView *container = _transitionContext.containerView;
    
    if (!container) {
        return;
    }
    
    if (@available(iOS 16.0, *)) {
        //iOS16系统有问题，有时转来转去containersize没变化，这里补充保障一下，使其和父view同大小
        if (container.superview
            && CGRectEqualToRect(container.frame, container.superview.bounds)
            && UIViewAutoresizingNone == container.autoresizingMask) {
            container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
    }
    
    //先确保base和move的view都放入图层中
    BOOL iscreate = NO;
    self.baseTransBoard = [self obtainTransBoardForVC:YES isCreate:&iscreate];
    self.isBaseTransBoardCustom = iscreate;
    
    self.moveTransBoard = [self obtainTransBoardForVC:NO isCreate:&iscreate];
    self.isMoveTransBoardCustom = iscreate;
    
    if (BOTransitionTypeNavigation == _transitionType) {
        //navigation时，都在container里
        if (self.baseTransBoard.superview != container) {
            [container addSubview:self.baseTransBoard];
            _hasAddBaseWhenInitialViewHierarchy = YES;
        }
        
        if (self.moveTransBoard.superview != container) {
            [container addSubview:self.moveTransBoard];
            _hasAddMoveWhenInitialViewHierarchy = YES;
        }
        
        NSUInteger baseidx = [container.subviews indexOfObject:self.baseTransBoard];
        NSUInteger moveidx = [container.subviews indexOfObject:self.moveTransBoard];
        if (NSNotFound != baseidx
            && NSNotFound != moveidx
            && baseidx > moveidx) {
            [container insertSubview:self.moveTransBoard aboveSubview:self.baseTransBoard];
        }
    } else {
        //present时，只有moveview在container里
        if (self.moveTransBoard.superview != container) {
            [container addSubview:self.moveTransBoard];
        }
    }
    
    //发送消息
    id sender = (BOTransitionTypeNavigation == _transitionType ?
                 self.navigationController : nil);
    NSDictionary *senduserinfo = nil;
    UIViewController *didaddvc = (BOTransitionActMoveIn == _transitionAct) ? self.moveVC : self.baseVC;
    if (didaddvc) {
        senduserinfo = @{
            @"vc": didaddvc
        };
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BOTransitionVCViewDidMoveToContainer
                                                        object:sender
                                                      userInfo:senduserinfo];
    
    //添加用来测量动画时间的view
    if (self.timeRuler.superview != container) {
        [container addSubview:self.timeRuler];
    }
}

- (void)revertInitialViewHierarchy {
    //moveIn的revert，若有移入过move视图，移除
    if (BOTransitionActMoveIn == _transitionAct
        && _hasAddMoveWhenInitialViewHierarchy
        && self.moveTransBoard.superview == _transitionContext.containerView) {
        [self.moveTransBoard removeFromSuperview];
    }
    
    //moveOut的revert，若有移入过base视图，移除
    if (BOTransitionActMoveOut == _transitionAct
        && _hasAddBaseWhenInitialViewHierarchy
        && self.baseTransBoard.superview == _transitionContext.containerView) {
        [self.baseTransBoard removeFromSuperview];
    }
    
    [self removeCustomTransBoard];
    
    [self.timeRuler removeFromSuperview];
}

/*
 结束时，把图层放置到结束状态
 */
- (void)finalViewHierarchy {
    
    switch (_transitionAct) {
        case BOTransitionActMoveIn: {
            /*
             moveView在开始时已经移入进来了
             */
        }
            break;
        case BOTransitionActMoveOut: {
            /*
             系统会自动在completeTransition方法里把moveView移出，这里手动移出做下保障
             */
            if (BOTransitionTypeNavigation == self.transitionType) {
                [self.moveTransBoard removeFromSuperview];
            }
        }
            break;
        default:
            break;
    }
    
    [self removeCustomTransBoard];
    
    [self.timeRuler removeFromSuperview];
}

- (void)ncViewDidLayoutSubviews:(UINavigationController *)nc {
    if (self.navigationController == nc
        && BOTransitionTypeNavigation == self.transitionType
        && _transitionContext
        && _baseTransBoard
        && _moveTransBoard) {
        
        NSUInteger bidx = [_transitionContext.containerView.subviews indexOfObject:_baseTransBoard];
        NSUInteger midx = [_transitionContext.containerView.subviews indexOfObject:_moveTransBoard];
        if (NSNotFound != bidx
            && NSNotFound != midx
            && bidx > midx) {
            [_transitionContext.containerView insertSubview:_moveTransBoard aboveSubview:_baseTransBoard];
        }
    }
}

- (void)sendWillFinish:(BOOL)willFinish
                fromVC:(__weak UIViewController *)fromVC
                  toVC:(__weak UIViewController *)toVC
             toVCPtStr:(NSString *)toVCPtStr {
    NSMutableDictionary *sendinfo = @{
        @"act": @(self.transitionAct),
    }.mutableCopy;
    if (fromVC) {
        [sendinfo setObject:fromVC forKey:@"fromeVC"];
    }
    if (toVC) {
        [sendinfo setObject:toVC forKey:@"toVC"];
    }
    
    if ([fromVC respondsToSelector:@selector(bo_transitionWillCompletion:)]) {
        [fromVC bo_transitionWillCompletion:sendinfo];
    }
    if ([toVC respondsToSelector:@selector(bo_transitionWillCompletion:)]) {
        [toVC bo_transitionWillCompletion:sendinfo];
    }
    
    id sender = (BOTransitionTypeNavigation == _transitionType ?
                 self.navigationController : nil);
    [[NSNotificationCenter defaultCenter]\
     postNotificationName:BOTransitionWillAndMustCompletion
     object:sender
     userInfo:@{
        @"willFinish": @(willFinish),
        @"vcPt": toVCPtStr ? : @""
    }];
}

- (void)transitionAnimationDidEmit:(BOOL)willFinish {
    __weak UIViewController *fromvc;
    __weak UIViewController *tovc;
    if (self.transitionAct == BOTransitionActMoveIn) {
        fromvc = self.baseVC;
        tovc = self.moveVC;
    } else {
        fromvc = self.moveVC;
        tovc = self.baseVC;
    }
    
    //传递内存地址作为标记信息，不传指针是为了防止CompletionBlock延缓释放时机
    NSString *vcPtStr =\
    (tovc ? [NSString stringWithFormat:@"%p", tovc] : @"");
    
    /*
     传弱指针是为了不影响释放时机
     等提交的动画开始渲染后，再通知BOTransitionWillAndMustCompletion，使用addOperationWithBlock可以实现这个时机
     */
    __weak typeof(self) ws = self;
    [BOTransitionUtility addOperationBlockAfterScreenUpdates:^{
        [ws sendWillFinish:willFinish fromVC:fromvc toVC:tovc toVCPtStr:vcPtStr];
    } userInfo:nil];
}

// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (![self setupTransitionContext:transitionContext interactive:NO]) {
        [self makeTransitionComplete:NO isInteractive:NO];
        return;
    }
    
    [self makeAnimateTransition:transitionContext];
}

- (void)makeAnimateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [self initialViewHierarchy];
    
    [self loadEffectControlAr:NO];
    
    BOTransitionInfo transitioninfo = {0, NO, CGPointZero, CGPointZero};
    NSMutableArray<BOTransitionElement *> *elementar = @[].mutableCopy;
    [self makePrepareAndExecStep:BOTransitionStepInstallElements
                        elements:elementar
                  transitionInfo:transitioninfo
                         subInfo:nil];
    [self makePrepareAndExecStep:BOTransitionStepAfterInstallElements
                        elements:elementar
                  transitionInfo:transitioninfo
                         subInfo:nil];
    [self makePrepareAndExecStep:BOTransitionStepInitialAnimatableProperties
                        elements:elementar
                  transitionInfo:transitioninfo
                         subInfo:nil];
    
    transitioninfo.percentComplete = 1;
    
    BOOL needsani = elementar.count > 0;
    if (needsani) {
        //有动画时，依次执行对应的生命周期
        [self execAnimateDuration:sf_default_transition_dur
               percentStartAndEnd:CGPointMake(0, 1)
                    modifyUIBlock:^{
            [self makePrepareAndExecStep:BOTransitionStepTransitioning
                                elements:elementar
                          transitionInfo:transitioninfo
                                 subInfo:nil];
            [self makePrepareAndExecStep:BOTransitionStepFinalAnimatableProperties
                                elements:elementar
                          transitionInfo:transitioninfo
                                 subInfo:nil];
        }
                       completion:^(BOOL finished) {
            [self makePrepareAndExecStep:BOTransitionStepFinished
                                elements:elementar
                          transitionInfo:transitioninfo
                                 subInfo:nil];
            
            [self finalViewHierarchy];
            
            [self makeTransitionComplete:YES isInteractive:self.startWithInteractive];
        }];
    } else {
        //系统似乎不支持直接结束，需要有一个动画过程或者下个runloop才能调用结束。否则会周期错乱。
        [self execAnimateDuration:0
               percentStartAndEnd:CGPointMake(0, 1)
                    modifyUIBlock:nil
                       completion:^(BOOL finished) {
            //无动画时，直接完成变为结束状态，然后调用makeTransitionComplete告诉系统完成了转场。
            [self makePrepareAndExecStep:BOTransitionStepFinished
                                elements:elementar
                          transitionInfo:transitioninfo
                                 subInfo:nil];
            [self finalViewHierarchy];
            
            [self makeTransitionComplete:YES isInteractive:self.startWithInteractive];
        }];
    }
    
    [self transitionAnimationDidEmit:YES];
}

- (void)makeTransitionComplete:(BOOL)isFinish isInteractive:(BOOL)interactive {
    _effectControlAr = nil;
    [_transitionElementAr removeAllObjects];
    _transitionElementAr = nil;
    _triggerInteractiveTransitioning = NO;
    _startWithInteractive = NO;
    
    _baseTransBoard = nil;
    _moveTransBoard = nil;
    _isBaseTransBoardCustom = NO;
    _isMoveTransBoardCustom = NO;
    _hasAddBaseWhenInitialViewHierarchy = NO;
    _hasAddMoveWhenInitialViewHierarchy = NO;
    
    //ModalPresentation的moveIn时，以及moveOut失败时不清空baseVC、moveVC信息，手势交互还需要用到
    BOOL shouldclearvccontext = YES;
    if (BOTransitionTypeModalPresentation == _transitionType
        && (BOTransitionActMoveOut != _transitionAct
            || YES != isFinish)) {
        shouldclearvccontext = NO;
    }
    
    if (shouldclearvccontext) {
        _baseVC = nil;
        _moveVC = nil;
        _moveVCConfig = nil;
    }
    
    /*
     transitionAct 由外部控制，内部就不要修改了吧（出现animationEnded前）
     [transitionContext completeTransition:YES]会同步先执行外部的completion，再执行- (void)animationEnded:(BOOL)transitionCompleted {
     如果外部进行了push或pop等操作，会修改transitionAct为一个有效值，等下下次转场使用，此时再执行animationEnded:时不宜将其重置
     */
    _transitionAct = BOTransitionActNone;
    
    if (interactive) {
        if (isFinish) {
            [self.transitionContext finishInteractiveTransition];
            [self.transitionContext completeTransition:YES];
        } else {
            [self.transitionContext cancelInteractiveTransition];
            [self.transitionContext completeTransition:NO];
        }
    } else {
        [self.transitionContext completeTransition:isFinish];
    }
    
    _transitionContext = nil;
}

- (void)animationEnded:(BOOL)transitionCompleted {
    _effectControlAr = nil;
    [_transitionElementAr removeAllObjects];
    _transitionElementAr = nil;
    _triggerInteractiveTransitioning = NO;
    _startWithInteractive = NO;
    _transitionContext = nil;
    
    //ModalPresentation的moveIn时，以及moveOut失败时不清空baseVC、moveVC信息，手势交互还需要用到
    BOOL shouldclearvccontext = YES;
    if (BOTransitionTypeModalPresentation == _transitionType
        && (BOTransitionActMoveOut != _transitionAct
            || NO != transitionCompleted)) {
        shouldclearvccontext = NO;
    }
    
    if (shouldclearvccontext) {
        _baseVC = nil;
        _moveVC = nil;
        _moveVCConfig = nil;
    }
}

#pragma mark - triggerInteractiveTransitioning

- (BOOL)wantsInteractiveStart {
    //需要返回NO，防止startInteractiveTransition使用动画时，系统自动把动画stop
    return NO;
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (![self setupTransitionContext:transitionContext interactive:YES]) {
        [self makeTransitionComplete:NO isInteractive:YES];
        return;
    } else if (!self.triggerInteractiveTransitioning
               || (UIGestureRecognizerStateBegan != self.transitionGes.transitionGesState
                   && UIGestureRecognizerStateChanged != self.transitionGes.transitionGesState)) {
        //        [self makeTransitionComplete:NO isInteractive:YES];
        [self makeAnimateTransition:transitionContext];
        return;
    }
    
    [self makeInteractiveTransition:transitionContext];
}

- (void)makeInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [self initialViewHierarchy];
    
    [self loadEffectControlAr:YES];
    
    BOTransitionPanGesture *ges = self.transitionGes;
    CGPoint beganloc = ges.delayTrigger ? ges.triggerDirectionInfo.location : ges.touchInfoAr.firstObject.CGRectValue.origin;
    CGPoint curloc = ges.touchInfoAr.lastObject.CGRectValue.origin;
    CGFloat percentComplete = [self obtainPercentCompletionBegan:beganloc
                                                            curr:curloc
                                                             ges:ges
                                                     distanceCoe:nil];
    BOTransitionInfo transitioninfo = {percentComplete, YES, beganloc, curloc};
    
    NSMutableArray<BOTransitionElement *> *elementar = @[].mutableCopy;
    [self makePrepareAndExecStep:BOTransitionStepInstallElements
                        elements:elementar
                  transitionInfo:transitioninfo
                         subInfo:nil];
    [self makePrepareAndExecStep:BOTransitionStepAfterInstallElements
                        elements:elementar
                  transitionInfo:transitioninfo
                         subInfo:nil];
    [self makePrepareAndExecStep:BOTransitionStepInitialAnimatableProperties
                        elements:elementar
                  transitionInfo:transitioninfo
                         subInfo:nil];
    
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepTransitioning
                   transitionInfo:transitioninfo
                         elements:elementar];
        }
    }];
    
    self.transitionElementAr = elementar;
    
    [self.transitionContext updateInteractiveTransition:0];
}

- (UIViewController *)obtainFirstResponseVC {
    switch (_transitionType) {
        case BOTransitionTypeModalPresentation:
            return self.moveVC;
        case BOTransitionTypeNavigation:
            return self.navigationController.topViewController;
        case BOTransitionTypeTabBar:
            return self.tabBarController.selectedViewController;
        default:
            return nil;
    }
}

/*
 duration < 0 时不执行动画
 percentStartAndEnd：记录该动画是把转场进度从x播放到y
 */
- (void)execAnimateDuration:(NSTimeInterval)duration
         percentStartAndEnd:(CGPoint)percentStartAndEnd
              modifyUIBlock:(void (^)(void))modifyUIBlock
                 completion:(void (^ __nullable)(BOOL finished))completion {
    if (!modifyUIBlock && !completion) {
        return;
    }
    
    if (_innerAnimatingVal) {
        NSLog(@"error:%s ~~~execAnimateDuration上次动画还没结束", __func__);
    }
    _innerAnimatingVal = @(percentStartAndEnd);
    
    self.timeRuler.alpha = 0;
    //暂不开启手势中断动画功能
    [UIView animateWithDuration:duration
                          delay:0
                        options:(UIViewAnimationOptionAllowAnimatedContent
                                 | UIViewAnimationOptionCurveLinear)
                     animations:^{
        self.timeRuler.alpha = 1;
        if (modifyUIBlock) {
            modifyUIBlock();
        }
    }
                     completion:^(BOOL finished) {
        self.innerAnimatingVal = nil;
        if (completion) {
            completion(finished);
        }
    }];
}

#pragma mark - gesture

/*
 0: 默认（ges内置会共存），不做处理
 1: ges优先
 2: otherGes优先
 3: 不判断，保留原有优先级
 4: ges优先并强制fail掉other
 */
- (NSInteger)boTransitionGRStrategyForGes:(BOTransitionPanGesture *)ges otherGes:(UIGestureRecognizer *)otherGes {
    UIViewController *curmoveVC = self.moveVC;
    if (!self.moveVC && BOTransitionTypeNavigation == _transitionType) {
        switch (_transitionType) {
            case BOTransitionTypeNavigation:
                curmoveVC = self.navigationController.viewControllers.lastObject;
                break;
            case BOTransitionTypeTabBar:
                curmoveVC = self.tabBarController.selectedViewController;
                break;
            default:
                break;
        }
        
    }
    
    BOTransitionConfig *tconfig = curmoveVC.bo_transitionConfig;
    NSDictionary *gesinfo = [ges.userInfo objectForKey:@"triggerGesInfo"];
    BOOL seriousmargin = NO;
    NSNumber *marginnum = [gesinfo objectForKey:@"margin"];
    if (nil != marginnum) {
        seriousmargin = marginnum.boolValue;
    }
    
    if (tconfig && seriousmargin) {
        return 4;
    }
    
    return 3;
}

- (CGFloat)obtainPercentCompletionBegan:(CGPoint)began
                                   curr:(CGPoint)curr
                                    ges:(BOTransitionPanGesture *)ges
                            distanceCoe:(CGFloat *)coe {
    UIView *container = self.transitionContext.containerView;
    if (!container) {
        return 0;
    }
    
    CGFloat percentComplete = 0;
    
    __block CGFloat specialpercent = -1;
    __block BOOL hasmakepercent = NO;
    [self.effectControlAr enumerateObjectsWithOptions:NSEnumerationReverse
                                           usingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioningGetPercent:gesture:)]) {
            NSNumber *percentnum = [obj bo_transitioningGetPercent:self gesture:self.transitionGes];
            if (nil != percentnum) {
                specialpercent = percentnum.floatValue;
                hasmakepercent = YES;
                *stop = YES;
            }
        }
    }];
    
    if (hasmakepercent) {
        percentComplete = specialpercent;
    } else {
        __block CGFloat distanceCoe = 1;
        __block BOOL hasmakecoe = NO;
        [self.effectControlAr enumerateObjectsWithOptions:NSEnumerationReverse
                                               usingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(bo_transitioning:distanceCoefficientForGes:)]) {
                NSNumber *distanceCoenum =\
                [obj bo_transitioning:self distanceCoefficientForGes:ges];
                if (nil != distanceCoenum) {
                    distanceCoe = distanceCoenum.floatValue;
                    hasmakecoe = YES;
                    *stop = YES;
                }
            }
        }];
        
        CGSize containersz = container.bounds.size;
        
        switch (ges.triggerDirectionInfo.mainDirection) {
            case UISwipeGestureRecognizerDirectionUp:
                if (!hasmakecoe) {
                    distanceCoe = 1;
                    hasmakecoe = YES;
                }
                percentComplete = (began.y - curr.y) / (containersz.height * distanceCoe);
                break;
            case UISwipeGestureRecognizerDirectionLeft:
                if (!hasmakecoe) {
                    distanceCoe = 1;
                    hasmakecoe = YES;
                }
                percentComplete = (began.x - curr.x) / (containersz.width * distanceCoe);
                break;
            case UISwipeGestureRecognizerDirectionDown:
                if (!hasmakecoe) {
                    distanceCoe = 1;
                    hasmakecoe = YES;
                }
                percentComplete = (curr.y - began.y) / (containersz.height * distanceCoe);
                break;
            case UISwipeGestureRecognizerDirectionRight:
                if (!hasmakecoe) {
                    distanceCoe = 1;
                    hasmakecoe = YES;
                }
                percentComplete = (curr.x - began.x) / (containersz.width * distanceCoe);
                break;
            default:
                break;
        }
        
        if (coe) {
            *coe = distanceCoe;
        }
    }
    
    percentComplete = MAX(0.f, MIN(percentComplete, 1.f));
    
    return percentComplete;
}

/*
 nil: 不开始，但不允许该手势继续滑动，一会儿当触发了某个方向时会继续尝试触发
 YES: 开始手势
 NO: 不可以开始并且取消本次手势响应
 */
- (NSNumber *)boTransitionGesShouldAndWillBegin:(BOTransitionPanGesture *)ges
                           specialMainDirection:(nonnull UISwipeGestureRecognizerDirection *)mainDirection
                                        subInfo:(nullable NSDictionary *)subInfo {
    if ([subInfo[@"type"] isEqualToString:@"needsRecoverWhenTouchDown"]) {
        return @(YES);
    }
    
    if (_transitionContext) {
        return @(NO);
    }
    
    UIViewController *firstResponseVC = [self obtainFirstResponseVC];
    if (!firstResponseVC) {
        return @(NO);
    }
    
    BOTransitionConfig *tconfig = firstResponseVC.bo_transitionConfig;
    if (!tconfig) {
        return @(NO);
    }
    
    id<BOTransitionConfigDelegate> configdelegate = tconfig.configDelegate;
    if (!configdelegate) {
        configdelegate = (id)firstResponseVC;
    }
    
    BOOL hassuspend = NO;
    BOOL hasvalid = NO;
    BOOL validismoveout = NO; //hasvalid=YES是才有效
    NSDictionary *validgesinfo = nil;
    for (NSDictionary *gesinfo in tconfig.gesInfoAr) {
        BOOL moveoutact = (1 == [(NSNumber *)[gesinfo objectForKey:@"act"] integerValue]);
        UISwipeGestureRecognizerDirection regdirection =\
        [(NSNumber *)[gesinfo objectForKey:@"direction"] unsignedIntegerValue];
        BOOL seriousMargin = NO;
        NSNumber *seriousMarginnum = [gesinfo objectForKey:@"margin"];
        if (nil != seriousMarginnum) {
            seriousMargin = seriousMarginnum.boolValue;
        }
        
        NSNumber *gesvalid = nil;
        if (seriousMargin) {
            BOTransitionGesBeganInfo gesBeganInfo = ges.gesBeganInfo;
            //手势横方向和竖直的夹角最小大概27度也判定有效 tan(27度)~=0.5
            CGFloat defminrate = 0.5;
            //距离边缘距离小于27
            CGFloat defmarginspace = 27;
            BOOL directjudegsuc = NO;
            if (UISwipeGestureRecognizerDirectionRight == regdirection) {
                //向右的权重超过指定权重，起始点距离屏幕左侧边缘小于指定距离
                directjudegsuc = (gesBeganInfo.directionWeight.right > defminrate
                                  && gesBeganInfo.marginSpace.left < defmarginspace);
            } else if (UISwipeGestureRecognizerDirectionLeft == regdirection) {
                //向左的权重超过指定权重，起始点距离屏幕右侧边缘小于指定距离
                directjudegsuc = (gesBeganInfo.directionWeight.left > defminrate
                                  && gesBeganInfo.marginSpace.right < defmarginspace);
            }
            
            if (directjudegsuc) {
                //若默认的主方向与希望的方向不同，进行修改
                if (mainDirection
                    && *mainDirection != regdirection) {
                    *mainDirection = regdirection;
                }
                gesvalid = @(YES);
                //allowRecover默认YES，当手势返回原点后，转场会取消，再移动手势会重新尝试触发，有些可以和页面内手势同时响应的场景可以用到
                //严格的边缘手势就不用了，没有必要，严格的边缘手势并不与页面内的其它手势共存
                [ges.userInfo setObject:@(NO) forKey:@"allowRecover"];
            } else {
                gesvalid = @(NO);
            }
        } else {
            NSDictionary *otherSVResponsedic = subInfo[@"otherSVResponse"];
            CGPoint othersvrespt = CGPointZero;
            NSValue *othersvresval = otherSVResponsedic[@"info"];
            if (nil != othersvresval) {
                othersvrespt = othersvresval.CGPointValue;
            }
            if (regdirection == ges.triggerDirectionInfo.mainDirection
                && (2 != othersvrespt.x)) {
                //没有其他scrollview相应，或者响应到底或者bounces了，可以实施其他手势了
                BOOL allowBeganWithSVBounces = NO;
                NSNumber *allowBeganWithSVBouncesnum = [gesinfo objectForKey:@"allowBeganWithSVBounces"];
                if (nil != allowBeganWithSVBouncesnum) {
                    allowBeganWithSVBounces = allowBeganWithSVBouncesnum.boolValue;
                }
                
                /*
                 非其他sv的bounces开始或允许其他sv的bounces开始
                 方向相符
                 起始横竖和触发横竖相符
                 */
                if (!ges.beganWithSVBounces
                    || allowBeganWithSVBounces) {
                    
                    UISwipeGestureRecognizerDirection verd =\
                    (UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown);
                    BOOL initialisVertical = (verd & ges.initialDirectionInfo.mainDirection) > 0;
                    BOOL triggerisVertical = (verd & ges.triggerDirectionInfo.mainDirection) > 0;
                    
                    //命中了方向，且起始方向也一致，才认为此次手势的用户意图符合
                    if ((ges.triggerDirectionInfo.mainDirection & regdirection) > 0
                        && initialisVertical == triggerisVertical) {
                        
                        __block BOOL othersvconfict = NO;
                        [ges.otherSVRespondedDirectionRecord enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key,
                                                                                                 NSDictionary * _Nonnull gesinfo,
                                                                                                 BOOL * _Nonnull stop) {
                            CGPoint svrespt = CGPointZero;
                            NSValue *svresval = gesinfo[@"info"];
                            if (nil != svresval) {
                                svrespt = svresval.CGPointValue;
                            }
                            
                            //如果有一个明确开始过的手势，竖直、左右维度和标识方向不符，则认为意图已经被转移，无效本次手势
                            if (svrespt.x > 0
                                && 2 == svrespt.y) {
                                BOOL theobjisver = ((key.unsignedIntegerValue & verd) > 0);
                                if (theobjisver != triggerisVertical) {
                                    othersvconfict = YES;
                                    *stop = YES;
                                }
                            }
                        }];
                        
                        if (othersvconfict) {
                            //响应过了其它sv的其它方向，本手势不进行转场了，显式cancel
                            gesvalid = @(NO);
                        } else {
                            gesvalid = @(YES);
                        }
                    }
                } else {
                    //bounces行为和预期不符，显式cancel
                    gesvalid = @(NO);
                }
            }
        }
        
        if (nil != gesvalid) {
            if (gesvalid.boolValue) {
                hasvalid = YES;
                validismoveout = moveoutact;
                validgesinfo = gesinfo;
                break;
            }
        } else {
            hassuspend = YES;
        }
        
    }
    
    if (hasvalid) {
        NSMutableDictionary *processsubinfo = (subInfo ? : @{}).mutableCopy;
        if (validgesinfo.count > 0) {
            [processsubinfo addEntriesFromDictionary:validgesinfo];
        }
        if (BOTransitionTypeNavigation == self.transitionType
            && self.navigationController) {
            [processsubinfo setObject:self.navigationController forKey:@"nc"];
        }
        
        if (validismoveout) {
            if (BOTransitionTypeNavigation == self.transitionType) {
                if (self.navigationController.viewControllers.count <= 1
                    || tconfig.moveOutUseOrigin) {
                    //navigationController时，若只有一个VC，不尝试moveOut
                    return @(NO);
                }
            }
            
            if ([configdelegate respondsToSelector:@selector(bo_trans_shouldMoveOutVC:gesture:transitionType:subInfo:)]) {
                NSNumber *control = [configdelegate bo_trans_shouldMoveOutVC:firstResponseVC
                                                                     gesture:ges
                                                              transitionType:self.transitionType
                                                                     subInfo:processsubinfo];
                if (nil == control
                    || !control.boolValue) {
                    //configdelegate返回不允许
                    return control;
                }
            }
            
            //开始moveout
            __weak typeof(self) ws = self;
            [ges.userInfo setObject:^{
                ws.triggerInteractiveTransitioning = YES;
                
                BOOL takeover = NO;
                if ([configdelegate respondsToSelector:@selector(bo_trans_actMoveOutVC:gesture:transitionType:subInfo:)]) {
                    takeover = [configdelegate bo_trans_actMoveOutVC:firstResponseVC
                                                             gesture:ges
                                                      transitionType:ws.transitionType
                                                             subInfo:processsubinfo];
                }
                
                if (!takeover) {
                    //未接管，内部调用转场方法
                    switch (self.transitionType) {
                        case BOTransitionTypeModalPresentation: {
                            [firstResponseVC.presentingViewController dismissViewControllerAnimated:YES
                                                                                         completion:nil];
                        }
                            break;
                        case BOTransitionTypeNavigation: {
                            [ws.navigationController popViewControllerAnimated:YES];
                        }
                            break;
                        case BOTransitionTypeTabBar: {
                            //暂不支持，待开发
                        }
                            break;
                        default:
                            break;
                    }
                }
                
            }
                             forKey:@"beganBlock"];
            [ges.userInfo setObject:validgesinfo ? : @{} forKey:@"triggerGesInfo"];
            
            return @(YES);
        } else {
            UIViewController *moveInVC;
            void (^pushblock)(void);
            //先尝试move0In逻辑，moveIn不需要快捷属性，只读delegate
            NSMutableDictionary *usubif = (subInfo ? : @{}).mutableCopy;
            if (validgesinfo.count > 0) {
                [usubif addEntriesFromDictionary:validgesinfo];
            }
            if (configdelegate &&
                [configdelegate respondsToSelector:@selector(bo_trans_moveInVCWithGes:transitionType:subInfo:)]) {
                NSDictionary *moveindic = [configdelegate bo_trans_moveInVCWithGes:ges
                                                                    transitionType:self.transitionType
                                                                           subInfo:usubif];
                if (!moveindic
                    || 0 == moveindic.count) {
                    return nil;
                }
                
                NSString *actstr = [moveindic objectForKey:@"act"];
                if (actstr
                    && [actstr isEqualToString:@"fail"]) {
                    //显式cancel
                    return @(NO);
                }
                
                moveInVC = [moveindic objectForKey:@"vc"];
                __weak typeof(self) ws = self;
                if (moveInVC
                    && [moveInVC isKindOfClass:[UIViewController class]]) {
                    [ges.userInfo setObject:^{
                        ws.triggerInteractiveTransitioning = YES;
                        switch (self.transitionType) {
                            case BOTransitionTypeModalPresentation: {
                                //??? presentation暂不支持手势弹起
                            }
                                break;
                            case BOTransitionTypeNavigation: {
                                [ws.navigationController pushViewController:moveInVC animated:YES];
                            }
                                break;
                            case BOTransitionTypeTabBar: {
                                //暂不支持，待开发
                            }
                                break;
                            default:
                                break;
                        }
                    }
                                     forKey:@"beganBlock"];
                    [ges.userInfo setObject:validgesinfo ? : @{} forKey:@"triggerGesInfo"];
                    
                    return @(YES);
                } else {
                    pushblock = [moveindic objectForKey:@"moveInBlock"];
                    
                    if (pushblock) {
                        [ges.userInfo setObject:^{
                            ws.triggerInteractiveTransitioning = YES;
                            pushblock();
                        }
                                         forKey:@"beganBlock"];
                        [ges.userInfo setObject:validgesinfo ? : @{} forKey:@"triggerGesInfo"];
                        return @(YES);
                    } else {
                        return nil;
                    }
                }
                
            } else {
                return @(NO);
            }
        }
    } else if (hassuspend) {
        return nil;
    } else {
        //没有识别到的，也没有待定的，那就cancel手势吧
        return @(NO);
    }
    
}

- (BOOL)needsCancelTransition:(CGPoint)beganPt
                       currPt:(CGPoint)currPt
             triggerDirection:(UISwipeGestureRecognizerDirection)direction
                    hasElePin:(BOOL)hasElePin {
    if (hasElePin) {
        return (fabs(currPt.x - beganPt.x) <= 4
                && fabs(currPt.y - beganPt.y) <= 4);
        
    } else {
        switch (direction) {
            case UISwipeGestureRecognizerDirectionUp:
                return (currPt.y >= (beganPt.y));
            case UISwipeGestureRecognizerDirectionDown:
                return (currPt.y <= (beganPt.y));
            case UISwipeGestureRecognizerDirectionLeft:
                return (currPt.x >= (beganPt.x));
            case UISwipeGestureRecognizerDirectionRight:
                return (currPt.x <= (beganPt.x));
            default:
                return NO;
                break;
        }
    }
}

- (CGFloat)obtainMaxFrameChangeCenterDistance:(BOOL)isToEnd {
    __block CGFloat dis = 0;
    [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.frameAllow) {
            CGPoint tocenter = CGPointMake(CGRectGetMidX(isToEnd ?
                                                         obj.frameTo : obj.frameFrom),
                                           CGRectGetMidY(isToEnd ?
                                                         obj.frameTo : obj.frameFrom));
            CALayer *dislayer = (obj.transitionView.layer.presentationLayer ?
                                 : obj.transitionView.layer);
            CGPoint currcenter = CGPointMake(CGRectGetMidX(dislayer.frame),
                                             CGRectGetMidY(dislayer.frame));
            
            CGFloat maxdis = MAX(fabs(tocenter.x - currcenter.x),
                                 fabs(tocenter.y - currcenter.y));
            dis = MAX(maxdis, dis);
        }
    }];
    return dis;
}

- (void)boTransitionGesStateDidChange:(BOTransitionPanGesture *)ges {
    CGPoint beganloc = ges.triggerDirectionInfo.location;
    CGPoint curloc = ges.touchInfoAr.lastObject.CGRectValue.origin;
    
    CGFloat distanceCoe = 1;
    CGFloat percentComplete = [self obtainPercentCompletionBegan:beganloc
                                                            curr:curloc
                                                             ges:ges
                                                     distanceCoe:&distanceCoe];
    BOTransitionInfo transitioninfo = {percentComplete, YES, beganloc, curloc};
    switch (ges.transitionGesState) {
        case UIGestureRecognizerStateBegan: {
            if (_innerAnimatingVal && _transitionContext) {
                self.shouldRunAniCompletionBlock = NO;
                CGFloat curanipercent = self.timeRuler.layer.presentationLayer.opacity;
                CGPoint inneranise = _innerAnimatingVal.CGPointValue;
                
                CGFloat totalpercent = [BOTransitionUtility lerpV0:inneranise.x v1:inneranise.y t:curanipercent];
                BOTransitionInfo mofifytinfo = transitioninfo;
                mofifytinfo.percentComplete = totalpercent;
                CGPoint virturlbeganpt = curloc;
                switch (ges.triggerDirectionInfo.mainDirection) {
                    case UISwipeGestureRecognizerDirectionUp:
                        virturlbeganpt.y = curloc.y + (totalpercent * CGRectGetHeight(ges.view.bounds) * distanceCoe);
                        break;
                    case UISwipeGestureRecognizerDirectionLeft:
                        virturlbeganpt.x = curloc.x + (totalpercent * CGRectGetWidth(ges.view.bounds) * distanceCoe);
                        break;
                    case UISwipeGestureRecognizerDirectionDown:
                        virturlbeganpt.y = curloc.y - (totalpercent * CGRectGetHeight(ges.view.bounds) * distanceCoe);
                        break;
                    case UISwipeGestureRecognizerDirectionRight:
                        virturlbeganpt.x = curloc.x - (totalpercent * CGRectGetWidth(ges.view.bounds) * distanceCoe);
                        break;
                    default:
                        break;
                }
                [ges insertBeganPt:virturlbeganpt];
                [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj interruptAnimationAndResetPorperty:self
                                             transitionInfo:transitioninfo
                                                    subInfo:@{@"aniPercent": @(curanipercent)}];
                }];
                [self.timeRuler.layer removeAllAnimations];
                break;
            } else if (ges.userInfo.count > 0) {
                /*
                 将正在活跃UI控件终止，比如文本输入、键盘弹出状态等，
                 */
                [ges.view.window endEditing:YES];
                
                void (^beganblock)(void) = ges.userInfo[@"beganBlock"];
                if (beganblock) {
                    beganblock();
                    [ges.userInfo removeObjectForKey:@"beganBlock"];
                }
            }
        }
        case UIGestureRecognizerStateChanged: {
            if (!_transitionContext) {
                return;
            }
            
            __block BOOL haselepin = NO;
            [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj execTransitioning:self
                                  step:BOTransitionStepTransitioning
                        transitionInfo:transitioninfo
                               subInfo:nil];
                if (obj.frameShouldPin) {
                    haselepin = YES;
                }
            }];
            [self.transitionContext updateInteractiveTransition:percentComplete];
            
            if (percentComplete <= 0
                && [self needsCancelTransition:beganloc
                                        currPt:curloc
                              triggerDirection:ges.triggerDirectionInfo.mainDirection
                                     hasElePin:haselepin]) {
                BOOL allowrecover = YES;
                NSNumber *allowRecoverval = [ges.userInfo objectForKey:@"allowRecover"];
                if (nil != allowRecoverval) {
                    allowrecover = allowRecoverval.boolValue;
                }
                
                if (allowrecover) {
                    //需要取消了
                    [ges makeGesStateCanceledButCanRetryBegan];
                }
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            //            NSLog(@"Ended");
        }
        case UIGestureRecognizerStateCancelled: {
            if (!_transitionContext) {
                return;
            }
            
            CGPoint vel = [ges velocityInCurrView];
            
            NSNumber *intentcomplete = nil;
            //横滑较小，竖滑较大
            CGFloat vellimitdef = 260;
            switch (ges.triggerDirectionInfo.mainDirection) {
                case UISwipeGestureRecognizerDirectionUp:
                    vellimitdef = 640;
                    if (vel.y <= -vellimitdef) {
                        intentcomplete = @(YES);
                    } else if (vel.y >= vellimitdef) {
                        intentcomplete = @(NO);
                    }
                    break;
                case UISwipeGestureRecognizerDirectionLeft:
                    if (vel.x <= -vellimitdef) {
                        intentcomplete = @(YES);
                    } else if (vel.x >= vellimitdef) {
                        intentcomplete = @(NO);
                    }
                    break;
                case UISwipeGestureRecognizerDirectionDown:
                    vellimitdef = 640;
                    if (vel.y <= -vellimitdef) {
                        intentcomplete = @(NO);
                    } else if (vel.y >= vellimitdef) {
                        intentcomplete = @(YES);
                    }
                    break;
                case UISwipeGestureRecognizerDirectionRight:
                    if (vel.x <= -vellimitdef) {
                        intentcomplete = @(NO);
                    } else if (vel.x >= vellimitdef) {
                        intentcomplete = @(YES);
                    }
                    break;
                default:
                    break;
            }
            
            if (nil == intentcomplete) {
                //没有速度倾向时，用当前的距离完成度来判断
                if (percentComplete >= 0.5) {
                    intentcomplete = @(YES);
                } else {
                    intentcomplete = @(NO);
                }
            }
            
            __block BOOL canfinish = YES;
            __block NSNumber *specialcanfinish = nil;
            [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                               NSUInteger idx,
                                                               BOOL * _Nonnull stop) {
                if ([obj respondsToSelector:@selector(bo_transitioningShouldFinish:percentComplete:intentComplete:gesture:)]) {
                    specialcanfinish = [obj bo_transitioningShouldFinish:self
                                                         percentComplete:percentComplete
                                                          intentComplete:intentcomplete
                                                                 gesture:self.transitionGes];
                    if (nil != specialcanfinish) {
                        *stop = YES;
                    }
                }
            }];
            
            //有指定用指定的，没有则用默认的
            if (nil != specialcanfinish) {
                canfinish = specialcanfinish.boolValue;
            } else {
                canfinish = intentcomplete.boolValue;
            }
            
            [self makePrepareAndExecStep:BOTransitionStepInteractiveEnd
                                elements:self.transitionElementAr
                          transitionInfo:transitioninfo
                                 subInfo:@{@"finish": @(canfinish)}];
            
            if (canfinish) {
                [self makePrepareAndExecStep:BOTransitionStepWillFinish
                                    elements:self.transitionElementAr
                              transitionInfo:transitioninfo
                                     subInfo:nil];
                
                CGFloat maxdis = [self obtainMaxFrameChangeCenterDistance:YES];
                CGFloat mindur = maxdis / 2400.f;
                if (maxdis > 8) {
                    mindur = MAX(mindur, 0.12);
                }
                CGFloat dur = MAX(mindur, (1.f - percentComplete) * sf_default_transition_dur);
                transitioninfo.percentComplete = 1;
                self.shouldRunAniCompletionBlock = YES;
                [self execAnimateDuration:dur
                       percentStartAndEnd:CGPointMake(percentComplete, 1)
                            modifyUIBlock:^{
                    [self makePrepareAndExecStep:BOTransitionStepFinalAnimatableProperties
                                        elements:self.transitionElementAr
                                  transitionInfo:transitioninfo
                                         subInfo:@{@"ani": @(YES)}];
                }
                               completion:^(BOOL finished) {
                    if (!self.shouldRunAniCompletionBlock) {
                        return;
                    }
                    self.shouldRunAniCompletionBlock = NO;
                    
                    [ges clearSaveContext];
                    
                    [self makePrepareAndExecStep:BOTransitionStepFinished
                                        elements:self.transitionElementAr
                                  transitionInfo:transitioninfo
                                         subInfo:nil];
                    
                    [self.transitionContext updateInteractiveTransition:transitioninfo.percentComplete];
                    [self finalViewHierarchy];
                    
                    [self makeTransitionComplete:YES isInteractive:YES];
                }];
            } else {
                [self makePrepareAndExecStep:BOTransitionStepWillCancel
                                    elements:self.transitionElementAr
                              transitionInfo:transitioninfo
                                     subInfo:nil];
                
                /*
                 若起点和当前点相聚较远,或当前有进度，执行取消动画
                 若非如此，那便是拖拽到了起点附近或重合，此时不需执行动画，直接恢复状态即可
                 */
                NSNumber *durval;
                
                if (percentComplete <= 0) {
                    __block BOOL haselepin = NO;
                    [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.frameShouldPin) {
                            haselepin = YES;
                        }
                    }];
                    
                    if ([self needsCancelTransition:beganloc
                                             currPt:curloc
                                   triggerDirection:ges.triggerDirectionInfo.mainDirection
                                          hasElePin:haselepin]) {
                        //需要无动画取消
                        durval = @(0.f);
                    }
                }
                
                if (nil == durval) {
                    CGFloat maxdis = [self obtainMaxFrameChangeCenterDistance:NO];
                    CGFloat mindur = maxdis / 2400.f;
                    if (maxdis > 8) {
                        mindur = MAX(mindur, 0.12);
                    }
                    durval = @(MAX(mindur, percentComplete * sf_default_transition_dur));
                }
                
                transitioninfo.percentComplete = 0;
                self.shouldRunAniCompletionBlock = YES;
                [self execAnimateDuration:durval.floatValue
                       percentStartAndEnd:CGPointMake(percentComplete, 0)
                            modifyUIBlock:^{
                    [self makePrepareAndExecStep:BOTransitionStepInitialAnimatableProperties
                                        elements:self.transitionElementAr
                                  transitionInfo:transitioninfo
                                         subInfo:@{@"ani": @(YES)}];
                }
                               completion:^(BOOL finished) {
                    if (!self.shouldRunAniCompletionBlock) {
                        return;
                    }
                    self.shouldRunAniCompletionBlock = NO;
                    [ges clearSaveContext];
                    
                    [self makePrepareAndExecStep:BOTransitionStepCancelled
                                        elements:self.transitionElementAr
                                  transitionInfo:transitioninfo
                                         subInfo:nil];
                    
                    [self.transitionContext updateInteractiveTransition:transitioninfo.percentComplete];
                    [self revertInitialViewHierarchy];
                    
                    [self makeTransitionComplete:NO isInteractive:YES];
                }];
            }
            
            if (self.moveVCConfig.allowInteractionInAnimating) {
                [ges saveCurrGesContextAndSetNeedsRecoverWhenTouchDown];
            } else {
                [self transitionAnimationDidEmit:canfinish];
            }
        }
            break;
        default:
            break;
    }
}

- (NSInteger)checkTransitionGes:(UIGestureRecognizer *)tGes
             otherTransitionGes:(UIGestureRecognizer *)otherTGes
                       makeFail:(BOOL)makeFail {
    UIViewController *curmoveVC = self.moveVC;
    if (!self.moveVC && BOTransitionTypeNavigation == _transitionType) {
        switch (_transitionType) {
            case BOTransitionTypeNavigation: {
                if (BOTransitionActNone == self.transitionAct) {
                    curmoveVC = self.navigationController.viewControllers.lastObject;
                }
            }
                break;
            case BOTransitionTypeTabBar:
                curmoveVC = self.tabBarController.selectedViewController;
                break;
            default:
                break;
        }
    }
    
    return [BOTransitioning checkWithVC:curmoveVC
                         transitionType:self.transitionType
                               makeFail:makeFail
                                baseGes:tGes
                     otherTransitionGes:otherTGes];
    
}

/*
 1 保留ges
 2 保留otherges
 0 没有判断出结果
 */
+ (NSInteger)checkWithVC:(UIViewController *)vc
          transitionType:(BOTransitionType)transitionType
                makeFail:(BOOL)makeFail
                 baseGes:(UIGestureRecognizer *)ges
      otherTransitionGes:(UIGestureRecognizer *)otherGes  {
    if (ges == otherGes
        || ges.view == otherGes.view) {
        return 0;
    }
    
    UIView *viewa = ges.view;
    UIView *viewb = otherGes.view;
    
    NSInteger prior = 0;
    BOTransitionConfig *tconfig = vc.bo_transitionConfig;
    id<BOTransitionConfigDelegate> configdelegate = tconfig.configDelegate;
    if (!configdelegate) {
        configdelegate = (id)vc;
    }
    
    if (BOTransitionTypeNavigation == transitionType
        && ges.view == otherGes.view) {
        BOOL usebotr = (tconfig && !tconfig.moveOutUseOrigin);
        if ([ges isKindOfClass:[BOTransitionPanGesture class]]) {
            prior = usebotr ? 1 : 2;
        } else {
            prior = usebotr ? 2 : 1;
        }
        
    } else {
        NSNumber *reccontrol;
        if ([configdelegate respondsToSelector:@selector(bo_trans_shouldRecTransitionGes:transitionType:subInfo:)]) {
            NSDictionary *subinfo;
            if (BOTransitionTypeNavigation == transitionType
                && [ges.view.nextResponder isKindOfClass:[UINavigationController class]]) {
                subinfo = @{
                    @"nc": ges.view.nextResponder
                };
            }
            reccontrol = [configdelegate bo_trans_shouldRecTransitionGes:ges
                                                          transitionType:transitionType
                                                                 subInfo:subinfo];
            
        }
        
        if (nil != reccontrol) {
            if (reccontrol.boolValue) {
                prior = 1;
            } else {
                prior = 2;
            }
        } else {
            NSInteger hier = [BOTransitionUtility viewHierarchy:viewa viewB:viewb];
            if (NSNotFound == hier
                || 0 == hier) {
                prior = 1;
            } else {
                BOOL gesBenable = YES;
                UINavigationController *bnc = (id)viewb.nextResponder;
                if ([bnc isKindOfClass:[UINavigationController class]]) {
                    if (bnc.viewControllers.count <= 1) {
                        gesBenable = NO;
                    }
                }
                
                if (!gesBenable) {
                    prior = 1;
                } else {
                    if (hier > 0) {
                        //otherGes是当前环境的子view中的转场
                        prior = 2;
                    } else {
                        
                        BOOL gesAEnable = YES;
                        UINavigationController *anc = (id)viewa.nextResponder;
                        if ([anc isKindOfClass:[UINavigationController class]]) {
                            if (anc.viewControllers.count <= 1) {
                                gesAEnable = NO;
                            }
                            
                            if (nil == anc.bo_transProxy) {
                                if (gesAEnable) {
                                    prior = 1;
                                } else {
                                    prior = 2;
                                }
                            } else {
                                prior = 0;
                            }
                        } else {
                            prior = 1;
                        }
                    }
                }
            }
        }
    }
    
    if (makeFail) {
        switch (prior) {
            case 1: {
                [BOTransitionPanGesture tryMakeGesFail:otherGes byGes:ges force:YES];
            }
                break;
            case 2: {
                [BOTransitionPanGesture tryMakeGesFail:ges byGes:otherGes force:YES];
            }
                break;
            default:
                break;
        }
    }
    
    return prior;
}

@end
