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

@property (nonatomic, strong) NSMutableDictionary<NSNumber *,
NSMutableArray<void (^)(BOTransitioning *transitioning, BOTransitionStep step,
BOTransitionElement *transitionItem, BOTransitionInfo transitionInfo,
NSDictionary * _Nullable info)> *
> *blockDic;

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
    if (block) {
        NSNumber *thekey = @(step);
        NSMutableArray<void (^)(BOTransitioning *transitioning,
                                BOTransitionStep,
                                BOTransitionElement * _Nonnull,
                                BOTransitionInfo,
                                NSDictionary * _Nullable)> *blockar =\
        [self.blockDic objectForKey:thekey];
        
        if (!blockar) {
            blockar = [NSMutableArray new];
            [self.blockDic setObject:blockar forKey:thekey];
        }
        [blockar addObject:block];
    }
}

- (void)execTransitioning:(BOTransitioning *)transitioning
                     step:(BOTransitionStep)step
           transitionInfo:(BOTransitionInfo)transitionInfo
                  subInfo:(nullable NSDictionary *)subInfo {
    
    NSMutableArray<void (^)(BOTransitioning *transitioning,
                            BOTransitionStep,
                            BOTransitionElement * _Nonnull,
                            BOTransitionInfo,
                            NSDictionary * _Nullable)> *blockar =\
    [self.blockDic objectForKey:@(step)];
    
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
    if (!thetrView) {
        return;
    }
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
        case BOTransitionStepAfterInstallElements: {
            if (self.fromView &&
                self.fromViewAutoHidden) {
                BOOL originfromhidden = self.fromView.hidden;
                self.fromView.hidden = YES;
                [self addToStep:BOTransitionStepCancelled
                          block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                    ws.fromView.hidden = originfromhidden;
                }];
                [self addToStep:BOTransitionStepCompleted
                          block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                    ws.fromView.hidden = originfromhidden;
                }];
            }
            
            if (self.toView &&
                self.toViewAutoHidden) {
                BOOL origintohidden = self.toView.hidden;
                self.toView.hidden = YES;
                [self addToStep:BOTransitionStepCancelled
                          block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                    ws.toView.hidden = origintohidden;
                }];
                [self addToStep:BOTransitionStepCompleted
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
                    self.framePinAnchor = CGPointMake((beganPt.x - CGRectGetMidX(thevrt)) / CGRectGetWidth(thevrt),
                                                      (beganPt.y - CGRectGetMidY(thevrt)) / CGRectGetHeight(thevrt));
                }
                if (self.frameAnimationWithTransform) {
                    thetrView.transform = CGAffineTransformIdentity;
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
                                //!!!!!errror
                                NSLog(@"~~~~~~~~！！！过大");
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
                                //!!!!!errror
                                NSLog(@"~~~~~~~~！！！过大");
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
        case BOTransitionStepCompleted: {
            if (self.frameAllow && !self.frameAnimationWithTransform) {
                thetrView.frame = self.frameOrigin;
            }
            if (self.alphaAllow) {
                thetrView.alpha = self.alphaOrigin;
            }
        }
            break;
        default:
            break;
    }
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
}

@end

const NSNotificationName BOTransitionWillAndMustCompletion =\
@"BOTransitionWillAndMustCompletion";

static CGFloat sf_default_transition_dur = 0.22f;

@interface BOTransitioning () <BOTransitionGestureDelegate>

@property (nonatomic, assign) BOTransitionType transitionType;

//present/push动作发生之前前已经在展示的基准VC
@property (nonatomic, strong) UIViewController *baseVC;

//present/push动作的入场VC以及 dismiss/pop动作的离场VC
@property (nonatomic, strong) UIViewController *moveVC;

@property (nonatomic, strong) UIView *commonBg;

@property (nonatomic, strong) BOTransitionPanGesture *transitionGes;

@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic, assign) BOOL triggerInteractiveTransitioning;

@property (nonatomic, strong) NSArray<id<BOTransitionEffectControl>> *effectControlAr;

@property (nonatomic, strong) NSMutableArray<BOTransitionElement *> *transitionElementAr;

@property (nonatomic, strong) NSValue *innerAnimatingVal;

//shijiankedu
@property (nonatomic, strong) UIView *timeRuler;

@property (nonatomic, assign) BOOL shouldRunAniCompletionBlock;

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

- (void)setMoveVC:(UIViewController *)moveVC {
    _moveVC = moveVC;
    _moveVCConfig = _moveVC.bo_transitionConfig;
}

- (BOOL)setupTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext {
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
    
    NSDictionary *effectconfig;
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
        //可以不判断protocol，省的有人不声明protocol只实现方法
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
    }
    return _commonBg;
}

#pragma mark - AnimatedTransitioning
- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return sf_default_transition_dur;
}

- (void)initialViewHierarchy {
    UIView *container = _transitionContext.containerView;
    switch (_transitionAct) {
        case BOTransitionActMoveIn: {
            //把moveVC移入图层，直接设置为finalFrame，转场效果靠transform动画
            
            self.moveVC.view.frame = [_transitionContext finalFrameForViewController:self.moveVC];
            
            if (self.moveVC.view.superview != container) {
                
                [container addSubview:self.moveVC.view];
            }
        }
            break;
        case BOTransitionActMoveOut: {
            switch (_transitionType) {
                case BOTransitionTypeNavigation: {
                    //把baseVC移入图层，直接设置为finalFrame，转场效果靠transform动画
                    self.baseVC.view.frame = [_transitionContext finalFrameForViewController:self.baseVC];
                    if (self.baseVC.view.superview != container) {
                        
                        [container insertSubview:self.baseVC.view
                                    belowSubview:self.moveVC.view];
                        
                    }
                }
                    break;
                case BOTransitionTypeModalPresentation: {
                    //不需要做
                }
                    break;
                case BOTransitionTypeTabBar: {
                    //wei shi xian
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
    
    if (self.timeRuler.superview != container) {
        [container addSubview:self.timeRuler];
    }
}

- (void)revertInitialViewHierarchy {
    switch (_transitionAct) {
        case BOTransitionActMoveIn: {
            //把moveVC移入图层，直接设置为finalFrame，转场效果靠transform动画
            [self.moveVC.view removeFromSuperview];
        }
            break;
        case BOTransitionActMoveOut: {
            //把baseVC移入图层，直接设置为finalFrame，转场效果靠transform动画
            if (self.moveVC.view.superview != _transitionContext.containerView) {
                self.moveVC.view.frame = [_transitionContext initialFrameForViewController:self.moveVC];
                [_transitionContext.containerView addSubview:self.moveVC.view];
            } else {
                
            }
            
            switch (_transitionType) {
                case BOTransitionTypeNavigation: {
                    if (self.baseVC.view.superview == _transitionContext.containerView) {
                        [self.baseVC.view removeFromSuperview];
                    }
                }
                    break;
                case BOTransitionTypeModalPresentation: {
                    //不需要做
                }
                    break;
                case BOTransitionTypeTabBar: {
                    //wei shi xian
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
    
    [self.timeRuler removeFromSuperview];
}

- (void)finalViewHierarchy {
    switch (_transitionAct) {
        case BOTransitionActMoveIn: {
            
        }
            break;
        case BOTransitionActMoveOut: {
            [self.moveVC.view removeFromSuperview];
        }
            break;
        default:
            break;
    }
    
    [self.timeRuler removeFromSuperview];
}

// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (![self setupTransitionContext:transitionContext]) {
        __weak typeof(self) ws = self;
        [BOTransitionUtility addCATransaction:@"boanimateTransition"
                               completionTask:^{
            [ws makeTransitionComplete:NO isInteractive:NO];
        }];
        return;
    }
    
    [self initialViewHierarchy];
    
    [self loadEffectControlAr:NO];
    
    BOTransitionInfo transitioninfo = {0, NO, CGPointZero, CGPointZero};
    NSMutableArray<BOTransitionElement *> *elementar = @[].mutableCopy;
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepInstallElements
                   transitionInfo:transitioninfo
                         elements:elementar];
        }
    }];
    
    [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:BOTransitionStepInstallElements
                transitionInfo:transitioninfo
                       subInfo:nil];
    }];
    
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepAfterInstallElements
                   transitionInfo:transitioninfo
                         elements:elementar];
        }
    }];
    
    [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:BOTransitionStepAfterInstallElements
                transitionInfo:transitioninfo
                       subInfo:nil];
    }];
    
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepInitialAnimatableProperties
                   transitionInfo:transitioninfo
                         elements:elementar];
        }
    }];
    
    [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:BOTransitionStepInitialAnimatableProperties
                transitionInfo:transitioninfo
                       subInfo:nil];
    }];
    
    [[NSNotificationCenter defaultCenter]\
     postNotificationName:BOTransitionWillAndMustCompletion
     object:self
     userInfo:@{
         @"finish": @(YES),
     }];
    
    transitioninfo.percentComplete = 1;
    
    BOOL needsani = elementar.count > 0;
    [self execAnimateDuration:needsani ? sf_default_transition_dur : 0
           percentStartAndEnd:CGPointMake(0, 1)
                modifyUIBlock:^{
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
        
        [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                           NSUInteger idx,
                                                           BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                [obj bo_transitioning:self
                       prepareForStep:BOTransitionStepFinalAnimatableProperties
                       transitionInfo:transitioninfo
                             elements:elementar];
            }
        }];
        
        [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj execTransitioning:self
                              step:BOTransitionStepFinalAnimatableProperties
                    transitionInfo:transitioninfo
                           subInfo:nil];
        }];
    }
                   completion:^(BOOL finished) {
        [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                           NSUInteger idx,
                                                           BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                [obj bo_transitioning:self
                       prepareForStep:BOTransitionStepCompleted
                       transitionInfo:transitioninfo
                             elements:elementar];
            }
        }];
        
        [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj execTransitioning:self
                              step:BOTransitionStepCompleted
                    transitionInfo:transitioninfo
                           subInfo:nil];
        }];
        
        [self finalViewHierarchy];
        
        [self makeTransitionComplete:YES isInteractive:NO];
    }];
}

- (void)makeTransitionComplete:(BOOL)didComplete isInteractive:(BOOL)interactive {
    _effectControlAr = nil;
    [_transitionElementAr removeAllObjects];
    _transitionElementAr = nil;
    _triggerInteractiveTransitioning = NO;
    
    //ModalPresentation的moveIn时，以及moveOut失败时不清空baseVC、moveVC信息，手势交互还需要用到
    BOOL shouldclearvccontext = YES;
    if (BOTransitionTypeModalPresentation == _transitionType
        && (BOTransitionActMoveOut != _transitionAct
            || YES != didComplete)) {
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
        if (didComplete) {
            [self.transitionContext finishInteractiveTransition];
            [self.transitionContext completeTransition:YES];
        } else {
            [self.transitionContext cancelInteractiveTransition];
            [self.transitionContext completeTransition:NO];
        }
    } else {
        [self.transitionContext completeTransition:didComplete];
    }
    
    _transitionContext = nil;
}

- (void)animationEnded:(BOOL)transitionCompleted {
    _effectControlAr = nil;
    [_transitionElementAr removeAllObjects];
    _transitionElementAr = nil;
    _triggerInteractiveTransitioning = NO;
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

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (![self setupTransitionContext:transitionContext]
        || !self.triggerInteractiveTransitioning
        || (UIGestureRecognizerStateBegan != self.transitionGes.transitionGesState
            && UIGestureRecognizerStateChanged != self.transitionGes.transitionGesState)) {
        __weak typeof(self) ws = self;
        [BOTransitionUtility addCATransaction:@"bostartInteractiveTransition"
                               completionTask:^{
            [ws makeTransitionComplete:NO isInteractive:YES];
        }];
        return;
    }
    
    [self initialViewHierarchy];
    
    [self loadEffectControlAr:YES];
    
    BOTransitionPanGesture *ges = self.transitionGes;
    CGPoint beganloc = ges.delayTrigger ? ges.triggerDirectionInfo.location : ges.touchInfoAr.firstObject.CGRectValue.origin;
    CGPoint curloc = ges.touchInfoAr.lastObject.CGRectValue.origin;
    CGFloat percentComplete = [self obtainPercentCompletionBegan:beganloc
                                                            curr:curloc
                                                       direction:ges.triggerDirectionInfo.mainDirection];
    BOTransitionInfo transitioninfo = {percentComplete, YES, beganloc, curloc};
    
    NSMutableArray<BOTransitionElement *> *elementar = @[].mutableCopy;
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepInstallElements
                   transitionInfo:transitioninfo
                         elements:elementar];
        }
    }];
    
    [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:BOTransitionStepInstallElements
                transitionInfo:transitioninfo
                       subInfo:nil];
    }];
    
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepAfterInstallElements
                   transitionInfo:transitioninfo
                         elements:elementar];
        }
    }];
    
    [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:BOTransitionStepAfterInstallElements
                transitionInfo:transitioninfo
                       subInfo:nil];
    }];
    
    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                       NSUInteger idx,
                                                       BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
            [obj bo_transitioning:self
                   prepareForStep:BOTransitionStepInitialAnimatableProperties
                   transitionInfo:(BOTransitionInfo){0, NO, CGPointZero, CGPointZero}
                         elements:elementar];
        }
    }];
    
    [elementar enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj execTransitioning:self
                          step:BOTransitionStepInitialAnimatableProperties
                transitionInfo:transitioninfo
                       subInfo:nil];
    }];
    
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
    if (duration <= 0) {
        if (modifyUIBlock) {
            modifyUIBlock();
        }
        
        if (completion) {
            [BOTransitionUtility addCATransaction:@"noanit"
                                   completionTask:^{
                completion(YES);
            }];
        }
        return;
    }
    
    if (_innerAnimatingVal) {
        NSLog(@"~~~~~~~~animateWithDuration出错");
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
    if (tconfig && (ges.triggerDirectionInfo.mainDirection
                    & tconfig.moveOutSeriousGesDirection)) {
        return 1;
    }
    
    return 3;
}

- (CGFloat)obtainPercentCompletionBegan:(CGPoint)began
                                   curr:(CGPoint)curr
                              direction:(UISwipeGestureRecognizerDirection)direction {
    UIView *container = self.transitionContext.containerView;
    if (!container) {
        return 0;
    }
    
    __block CGFloat distanceCoe = 1;
    __block BOOL hasmakecoe = NO;
    [self.effectControlAr enumerateObjectsWithOptions:NSEnumerationReverse
                                           usingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioningDistanceCoefficient:)]) {
            distanceCoe =\
            [obj bo_transitioningDistanceCoefficient:direction];
            hasmakecoe = YES;
            *stop = YES;
        }
    }];
    
    CGSize containersz = container.bounds.size;
    CGFloat percentComplete = 0;
    switch (direction) {
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
    
    
    percentComplete = MAX(0.f, MIN(percentComplete, 1.f));
    
    return percentComplete;
}

/*
 nil: 不开始，但不允许该手势继续滑动，一会儿当触发了某个方向时会继续尝试触发
 YES: 开始手势
 NO: 不可以开始并且取消本次手势响应
 */
- (NSNumber *)boTransitionGesShouldAndWillBegin:(BOTransitionPanGesture *)ges
                                        subInfo:(nullable NSDictionary *)subInfo {
    
    if ([subInfo[@"type"] isEqualToString:@"needsRecoverWhenTouchDown"]) {
        return @(YES);
    }
    
    if (ges.beganWithOtherSVBounces) {
        return @(NO);
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
    
    UIViewController *moveInVC;
    //先尝试move0In逻辑，moveIn不需要快捷属性，只读delegate
    if (configdelegate &&
        [configdelegate respondsToSelector:@selector(bo_trans_moveInVCWithGes:transitionType:subInfo:)]) {
        moveInVC = [configdelegate bo_trans_moveInVCWithGes:ges
                                             transitionType:self.transitionType
                                                    subInfo:subInfo];
    }
    
    __weak typeof(self) ws = self;
    if (moveInVC) {
        switch (self.transitionType) {
            case BOTransitionTypeModalPresentation: {
                //??? presentation暂不支持手势弹起（容器View都没有，咋触发手势）
            }
                break;
            case BOTransitionTypeNavigation: {
                ges.userInfo = @{
                    @"beganBlock": ^{
                        ws.triggerInteractiveTransitioning = YES;
                        [ws.navigationController pushViewController:moveInVC animated:YES];
                    }
                };
                return @(YES);
            }
            case BOTransitionTypeTabBar: {
                //暂不支持，待开发
            }
                break;
            default:
                break;
        }
    }
    
    if (BOTransitionTypeNavigation == self.transitionType) {
        
        if (self.navigationController.viewControllers.count <= 1
            || tconfig.moveOutUseOrigin) {
            //navigationController时，若只有一个VC，不尝试moveOut
            return @(NO);
        }
    }
    
    NSNumber *shouldMoveOut;
    //读取快捷属性
    if (tconfig.moveOutSeriousGesDirection & ges.triggerDirectionInfo.mainDirection) {
        /*
         严格手势判定，需要满足：
         1.从屏幕边缘滑入
         2.没有被其它scrollView提前响应过
         3.方向相符
         */
        BOOL ismargin = NO;
        if (!ges.delayTrigger &&
            UIGestureRecognizerStatePossible == ges.transitionGesState) {
            CGPoint pt1 = ges.touchInfoAr.firstObject.CGRectValue.origin;
            CGPoint ptmaybegan = pt1;
            if (ges.touchInfoAr.count >= 2) {
                CGPoint pt2 = ges.touchInfoAr[1].CGRectValue.origin;
                ptmaybegan.x = [BOTransitionUtility lerpV0:pt1.x v1:pt2.x t:-1];
                ptmaybegan.y = [BOTransitionUtility lerpV0:pt1.y v1:pt2.y t:-1];
            }
            
            CGFloat marginres = 27;
            switch (ges.triggerDirectionInfo.mainDirection) {
                case UISwipeGestureRecognizerDirectionLeft:
                    if (ptmaybegan.x
                        >=
                        CGRectGetMaxX(ges.view.bounds) - marginres) {
                        ismargin = YES;
                    }
                    break;
                case UISwipeGestureRecognizerDirectionRight:
                    if (ptmaybegan.x <= CGRectGetMinX(ges.view.bounds) + marginres) {
                        ismargin = YES;
                    }
                    break;
                default:
                    break;
            }
        }
        
        if (ismargin) {
            shouldMoveOut = @(ismargin);
        }
    }
    
    if (nil == shouldMoveOut) {
        NSNumber *otherSVResponseval = subInfo[@"otherSVResponse"];
        if (nil != otherSVResponseval &&
            2 == otherSVResponseval.integerValue) {
            return nil;
        }
        
        UISwipeGestureRecognizerDirection verd =\
        (UISwipeGestureRecognizerDirectionUp
         | UISwipeGestureRecognizerDirectionDown);
        BOOL initialisVertical = (verd & ges.initialDirectionInfo.mainDirection) > 0;
        BOOL triggerisVertical = (verd & ges.triggerDirectionInfo.mainDirection) > 0;
        if ((ges.triggerDirectionInfo.mainDirection & tconfig.moveOutGesDirection) > 0
            && initialisVertical == triggerisVertical) {
            BOOL isvalid = NO;
            switch (ges.otherSVRespondedDirectionRecord.count) {
                case 0: {
                    isvalid = YES;
                }
                    break;
                case 1: {
                    if (ges.otherSVRespondedDirectionRecord.anyObject.unsignedIntegerValue
                        ==
                        ges.triggerDirectionInfo.mainDirection) {
                        isvalid = YES;
                    }
                }
                    break;
                case 2: {
                    //判断两个方向时否同属竖向或横向
                    __block BOOL isequal = YES;
                    __block NSNumber *isvertical = nil;
                    NSUInteger verticaldirection = (UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown);
                    [ges.otherSVRespondedDirectionRecord enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                        BOOL currobjisvertical = ((obj.unsignedIntegerValue & verticaldirection) > 0);
                        
                        if (!isvertical) {
                            isvertical = @(currobjisvertical);
                        } else {
                            if (isvertical.boolValue != currobjisvertical) {
                                isequal = NO;
                                *stop = YES;
                            }
                        }
                    }];
                    
                    if (isequal) {
                        isvalid = YES;
                    }
                }
                    break;
                default:
                    break;
            }
            
            shouldMoveOut = @(isvalid);
        }
    }
    
    //没有触发moveIn逻辑，开始尝试moveOut逻辑
    if (nil != shouldMoveOut
        && shouldMoveOut.boolValue
        && configdelegate
        && [configdelegate respondsToSelector:@selector(bo_trans_shouldMoveOutVC:gesture:transitionType:subInfo:)]) {
        NSMutableDictionary *usubif = (subInfo ? : @{}).mutableCopy;
        if (BOTransitionTypeNavigation == self.transitionType
            && self.navigationController) {
            [usubif setObject:self.navigationController forKey:@"nc"];
        }
        NSNumber *control = [configdelegate bo_trans_shouldMoveOutVC:firstResponseVC
                                                             gesture:ges
                                                      transitionType:self.transitionType
                                                             subInfo:usubif];
        if (nil != control) {
            shouldMoveOut = control;
        }
    }
    
    if (nil != shouldMoveOut) {
        if (shouldMoveOut.boolValue) {
            switch (self.transitionType) {
                case BOTransitionTypeModalPresentation: {
                    ges.userInfo = @{
                        @"beganBlock": ^{
                            ws.triggerInteractiveTransitioning = YES;
                            [firstResponseVC.presentingViewController dismissViewControllerAnimated:YES
                                                                                         completion:nil];
                        }
                    };
                    return @(YES);
                }
                case BOTransitionTypeNavigation: {
                    ges.userInfo = @{
                        @"beganBlock": ^{
                            UINavigationController *sfnc = self.navigationController;
                            ws.triggerInteractiveTransitioning = YES;
                            BOOL takeover = NO;
                            if ([configdelegate respondsToSelector:@selector(bo_trans_actMoveOutVC:gesture:transitionType:subInfo:)]) {
                                takeover = [configdelegate bo_trans_actMoveOutVC:firstResponseVC
                                                                         gesture:ges
                                                                  transitionType:ws.transitionType
                                                                         subInfo:@{@"nc": sfnc}];
                            }
                            
                            if (!takeover) {
                                [ws.navigationController popViewControllerAnimated:YES];
                            }
                        }
                    };
                    return @(YES);
                }
                case BOTransitionTypeTabBar: {
                    //暂不支持，待开发
                }
                    break;
                default:
                    break;
            }
        } else {
            return @(NO);
        }
    }
    
    return nil;
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
    
    __block CGFloat distanceCoe = 1;
    __block BOOL hasmakecoe = NO;
    [self.effectControlAr enumerateObjectsWithOptions:NSEnumerationReverse
                                           usingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(bo_transitioningDistanceCoefficient:)]) {
            distanceCoe =\
            [obj bo_transitioningDistanceCoefficient:ges.triggerDirectionInfo.mainDirection];
            hasmakecoe = YES;
            *stop = YES;
        }
    }];
    
    CGFloat percentComplete = [self obtainPercentCompletionBegan:beganloc curr:curloc direction:ges.triggerDirectionInfo.mainDirection];
    BOTransitionInfo transitioninfo = {percentComplete, YES, beganloc, curloc};
    switch (ges.transitionGesState) {
        case UIGestureRecognizerStateBegan: {
            //            NSLog(@"Began");
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
                void (^beganblock)(void) = ges.userInfo[@"beganBlock"];
                if (beganblock) {
                    beganblock();
                }
                ges.userInfo = nil;
            }
        }
        case UIGestureRecognizerStateChanged: {
            if (!_transitionContext) {
                return;
            }
            //            NSLog(@"Changed");
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
                //需要取消了
                [ges makeGesStateCanceledButCanRetryBegan];
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
            BOOL cancomplete = YES;
            if (nil == intentcomplete) {
                cancomplete = (percentComplete >= 0.5);
            } else {
                cancomplete = intentcomplete.boolValue;
            }
            
            if (self.moveVCConfig.allowInteractionInAnimating) {
                [ges saveCurrGesContextAndSetNeedsRecoverWhenTouchDown];
            } else if (BOTransitionTypeNavigation == self.transitionType) {
                [[NSNotificationCenter defaultCenter]\
                 postNotificationName:BOTransitionWillAndMustCompletion
                 object:self
                 userInfo:@{
                     @"finish": @(cancomplete),
                 }];
            }
            
            [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                               NSUInteger idx,
                                                               BOOL * _Nonnull stop) {
                if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                    [obj bo_transitioning:self
                           prepareForStep:BOTransitionStepInteractiveEnd
                           transitionInfo:transitioninfo
                                 elements:self.transitionElementAr];
                }
            }];
            
            [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj execTransitioning:self
                                  step:BOTransitionStepInteractiveEnd
                        transitionInfo:transitioninfo
                               subInfo:@{@"finish": @(cancomplete)}];
            }];
            
            if (cancomplete) {
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
                    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                                       NSUInteger idx,
                                                                       BOOL * _Nonnull stop) {
                        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                            [obj bo_transitioning:self
                                   prepareForStep:BOTransitionStepFinalAnimatableProperties
                                   transitionInfo:transitioninfo
                                         elements:self.transitionElementAr];
                        }
                    }];
                    
                    [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj execTransitioning:self
                                          step:BOTransitionStepFinalAnimatableProperties
                                transitionInfo:transitioninfo
                                       subInfo:@{@"ani": @(YES)}];
                    }];
                }
                               completion:^(BOOL finished) {
                    if (!self.shouldRunAniCompletionBlock) {
                        return;
                    }
                    self.shouldRunAniCompletionBlock = NO;
                    
                    [ges clearSaveContext];
                    
                    //没有被touchesEvent接管才继续执行
                    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                                       NSUInteger idx,
                                                                       BOOL * _Nonnull stop) {
                        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                            [obj bo_transitioning:self
                                   prepareForStep:BOTransitionStepCompleted
                                   transitionInfo:transitioninfo
                                         elements:self.transitionElementAr];
                        }
                    }];
                    
                    [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj execTransitioning:self
                                          step:BOTransitionStepCompleted
                                transitionInfo:transitioninfo
                                       subInfo:nil];
                    }];
                    
                    [self.transitionContext updateInteractiveTransition:transitioninfo.percentComplete];
                    [self finalViewHierarchy];
                    
                    [self makeTransitionComplete:YES isInteractive:YES];
                }];
            } else {
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
                
                if (!durval) {
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
                    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                                       NSUInteger idx,
                                                                       BOOL * _Nonnull stop) {
                        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                            [obj bo_transitioning:self
                                   prepareForStep:BOTransitionStepInitialAnimatableProperties
                                   transitionInfo:transitioninfo
                                         elements:self.transitionElementAr];
                        }
                    }];
                    
                    [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj execTransitioning:self
                                          step:BOTransitionStepInitialAnimatableProperties
                                transitionInfo:transitioninfo
                                       subInfo:@{@"ani": @(YES)}];
                    }];
                }
                               completion:^(BOOL finished) {
                    if (!self.shouldRunAniCompletionBlock) {
                        return;
                    }
                    self.shouldRunAniCompletionBlock = NO;
                    [ges clearSaveContext];
                    
                    [self.effectControlAr enumerateObjectsUsingBlock:^(id<BOTransitionEffectControl>  _Nonnull obj,
                                                                       NSUInteger idx,
                                                                       BOOL * _Nonnull stop) {
                        if ([obj respondsToSelector:@selector(bo_transitioning:prepareForStep:transitionInfo:elements:)]) {
                            [obj bo_transitioning:self
                                   prepareForStep:BOTransitionStepCancelled
                                   transitionInfo:transitioninfo
                                         elements:self.transitionElementAr];
                        }
                    }];
                    
                    [self.transitionElementAr enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj execTransitioning:self
                                          step:BOTransitionStepCancelled
                                transitionInfo:transitioninfo
                                       subInfo:nil];
                    }];
                    
                    [self.transitionContext updateInteractiveTransition:transitioninfo.percentComplete];
                    [self revertInitialViewHierarchy];
                    
                    [self makeTransitionComplete:NO isInteractive:YES];
                }];
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
        || ges.class == otherGes.class) {
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
