//
//  BOTransitionGesture.m
//  BOTransition
//
//  Created by bo on 2020/11/13.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionGesture.h"
#import "BOTransitionUtility.h"

static UIEdgeInsets sf_common_contentInset(UIScrollView * __nonnull scrollView) {
    if (@available(iOS 11.0, *)) {
        return scrollView.adjustedContentInset;
    } else {
        return scrollView.contentInset;
    }
}

@implementation BOTransitionGesturePinchInfo

+ (instancetype)pinchInfoWithTouchAr:(NSArray<UITouch *> *)touchAr containerView:(UIView *)containerView {
    if (touchAr.count < 2
        || !containerView) {
        return nil;
    }
    
    BOTransitionGesturePinchInfo *pinchinfo = [BOTransitionGesturePinchInfo new];
    CGPoint thept1 = [touchAr[0] locationInView:containerView];
    CGPoint thept2 = [touchAr[1] locationInView:containerView];
    
    pinchinfo.pt1 = thept1;
    pinchinfo.pt2 = thept2;
    pinchinfo.centerPt = CGPointMake((thept1.x + thept2.x) / 2.0, (thept1.y + thept2.y) / 2.0);
    pinchinfo.space = pow((pow((thept2.x - thept1.x), 2) + pow((thept2.y - thept1.y), 2)), 0.5);
    
    pinchinfo.ts = [[NSDate date] timeIntervalSince1970];
    
    return pinchinfo;
}

- (BOOL)isPointEqual:(BOTransitionGesturePinchInfo *)pinchInfo {
    if (pinchInfo
        && CGPointEqualToPoint(pinchInfo.pt1, self.pt1)
        && CGPointEqualToPoint(pinchInfo.pt2, self.pt2)) {
        return YES;
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"tss:%@ pt1:%@, pt2:%@, center:%@, space:%@", @(_tsSinceFirst), @(_pt1), @(_pt2), @(_centerPt), @(_space)];
}

- (NSString *)debugDescription {
    return [self description];
}

@end

@interface BOTransitionGesture () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) UIGestureRecognizerState originState;

@property (nonatomic, strong) NSMutableArray<NSValue *> *panInfoAr;
@property (nonatomic, strong) NSMutableArray<BOTransitionGesturePinchInfo *> *pinchInfoAr;

@property (nonatomic, assign) BOTransitionGesSliceInfo initialDirectionInfo;
@property (nonatomic, assign) BOTransitionGesSliceInfo triggerDirectionInfo;
@property (nonatomic, assign) BOOL isDelayTrigger;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableDictionary *> *otherSVRespondedDirectionRecord;

@property (nonatomic, assign) UIGestureRecognizerState transitionGesState;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *careOtherDic;

//保存正在响应手势的UIScrollView，对它们的状态进行检测来判断是否应该开始dismiss
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *currPanScrollVAr;
@property (nonatomic, strong) NSMutableArray<NSValue *> *currPanScrollVSavOffsetAr;
@property (nonatomic, assign) BOOL beganWithSVBounces;

@property (nonatomic, assign) BOTransitionGestureBrief lastGesBrief;
@property (nonatomic, assign) BOOL needsRecoverWhenTouchDown;

@property (nonatomic, strong) NSMutableArray<UIGestureRecognizer *> *otherGesWillExecSimultaneouslyStrategy;

@property (nonatomic, strong) NSMutableArray<UITouch *> *touchAr;

@property (nonatomic, strong) NSString *gesType;

@end

static CGFloat sf_ges_conflict_wait_time = 0.12;

@implementation BOTransitionGesture

+ (CGFloat)gesConflictTime {
    return sf_ges_conflict_wait_time;
}

- (instancetype)initWithTransitionGesDelegate:(id<BOTransitionGestureDelegate>)transitionGesDelegate {
    self = [super initWithTarget:nil action:nil];
    if (self) {
        super.delegate = self;
        super.delaysTouchesBegan = NO;
        super.delaysTouchesEnded = NO;
        self.transitionGesDelegate = transitionGesDelegate;
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    return [self initWithTransitionGesDelegate:nil];
}

- (NSMutableDictionary *)userInfo {
    if (!_userInfo) {
        _userInfo = [NSMutableDictionary new];
    }
    return _userInfo;
}

- (CGPoint)velocityInCurrView {
    if (_panInfoAr.count < 2) {
        return CGPointZero;
    }
    
    __block NSInteger lastptidx = -1;
    __block NSInteger remoteidx = -1;
    [_panInfoAr enumerateObjectsWithOptions:NSEnumerationReverse
                                   usingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (lastptidx < 0) {
            lastptidx = idx;
        } else if (remoteidx < 0) {
            remoteidx = idx;
        } else {
            CGFloat ptts = obj.CGRectValue.size.width;
            if (ptts > 0) {
                CGFloat lastts = self.panInfoAr[lastptidx].CGRectValue.size.width;
                if (lastts <= 0) {
                    //失效
                    *stop = YES;
                }
                
                if (lastts - ptts > 0.16) {
                    //寻找结束
                    *stop = YES;
                } else {
                    remoteidx = idx;
                }
            } else {
                *stop = YES;
            }
        }
    }];
    
    CGPoint vel = CGPointZero;
    if (lastptidx >= 0
        && remoteidx >= 0
        && lastptidx != remoteidx) {
        CGRect lastptinfo = _panInfoAr[lastptidx].CGRectValue;
        CGRect remoteptinfo = _panInfoAr[remoteidx].CGRectValue;
        
        if (lastptinfo.size.width > 0 && remoteptinfo.size.width > 0) {
            CGFloat ptdur = lastptinfo.size.width - remoteptinfo.size.width;
            
            vel = CGPointMake((lastptinfo.origin.x - remoteptinfo.origin.x) / ptdur,
                              (lastptinfo.origin.y - remoteptinfo.origin.y) / ptdur);
        }
    }
    return vel;
}

- (void)reset {
    [super reset];
    [self innerReset];
}

- (void)innerReset {
    _panInfoAr = nil;

    [_pinchInfoAr removeAllObjects];
    _pinchInfoAr = nil;
    
    [_touchAr removeAllObjects];
    _touchAr = nil;
    _gesType = nil;
    
    switch (_originState) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            self.originState = UIGestureRecognizerStateCancelled;
            break;
        default:
            break;
    }
    
    _originState = UIGestureRecognizerStatePossible;
    _transitionGesState = UIGestureRecognizerStatePossible;
    
    [_otherGesWillExecSimultaneouslyStrategy removeAllObjects];
    //这个不用频繁释放了吧
    //    _otherGesWillExecSimultaneouslyStrategy = nil;
    
    _beganWithSVBounces = NO;
    [self clearCurrSVRecord];
    
    if (_careOtherDic) {
        [_careOtherDic removeAllObjects];
    }
    
    [_userInfo removeAllObjects];
}

- (void)makeGesStateCanceledWithCanRetryBegan:(BOOL)canRetryBegan {
    if (canRetryBegan) {
        switch (_transitionGesState) {
            case UIGestureRecognizerStateBegan:
            case UIGestureRecognizerStateChanged:
                self.transitionGesState = UIGestureRecognizerStateCancelled;
                break;
            default:
                break;
        }
        
        _transitionGesState = UIGestureRecognizerStatePossible;
        
        [_panInfoAr removeAllObjects];
        
        [_currPanScrollVSavOffsetAr removeAllObjects];
        [_otherSVRespondedDirectionRecord removeAllObjects];
        _isDelayTrigger = NO;
        _beganWithSVBounces = NO;
    } else {
        [self i_touchDidChange:self.touchAr
                         event:nil
                         state:UIGestureRecognizerStateCancelled];
        
        [_touchAr removeAllObjects];
        _touchAr = nil;
    }
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    if (preventingGestureRecognizer != self
        && [BOTransitionGesture isTransitonGes:preventingGestureRecognizer]) {
        return YES;
    }
    return NO;
}

- (NSMutableArray<NSValue *> *)touchInfoAr {
    return _panInfoAr;
}

- (NSMutableArray<UITouch *> *)touchAr {
    if (!_touchAr) {
        _touchAr = @[].mutableCopy;
    }
    return _touchAr;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    NSMutableArray<UITouch *> *usetouches = @[].mutableCopy;
    for (UITouch *touchitem in touches) {
        if (![self.touchAr containsObject:touchitem]) {
            [usetouches addObject:touchitem];
        }
    }
    
    if (usetouches.count > 0) {
        [self.touchAr addObjectsFromArray:usetouches];
        [self i_touchDidChange:usetouches
                         event:event
                         state:UIGestureRecognizerStateBegan];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    NSMutableArray<UITouch *> *usetouches = @[].mutableCopy;
    for (UITouch *touchitem in touches) {
        if ([self.touchAr containsObject:touchitem]) {
            [usetouches addObject:touchitem];
        }
    }
    if (usetouches.count > 0) {
        //pinch moved
        [self i_touchDidChange:usetouches
                         event:event
                         state:UIGestureRecognizerStateChanged];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    NSMutableArray<UITouch *> *usetouches = @[].mutableCopy;
    for (UITouch *touchitem in touches) {
        if ([self.touchAr containsObject:touchitem]) {
            [usetouches addObject:touchitem];
        }
    }
    if (usetouches.count > 0) {
        //pinch Ended
        [self i_touchDidChange:usetouches
                         event:event
                         state:UIGestureRecognizerStateEnded];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    NSMutableArray<UITouch *> *usetouches = @[].mutableCopy;
    for (UITouch *touchitem in touches) {
        if ([self.touchAr containsObject:touchitem]) {
            [usetouches addObject:touchitem];
        }
    }
    if (usetouches.count > 0) {
        //pinch Cancelled
        [self i_touchDidChange:usetouches
                         event:event
                         state:UIGestureRecognizerStateCancelled];
    }
}

static NSInteger sf_max_pinchInfo_count = 20;

- (void)i_touchDidChange:(NSArray<UITouch *> *)touches
                   event:(UIEvent *)event
                   state:(UIGestureRecognizerState)state {
    
    switch (state) {
        case UIGestureRecognizerStateBegan:
            for (UITouch *touchitem in touches) {
                for (UIView *theview = touchitem.view;
                     (theview != self.view && nil != theview);
                     theview = theview.superview) {
                    if ([theview isKindOfClass:[UIScrollView class]]) {
                        UIScrollView *scv = (UIScrollView *)theview;
                        if (scv.scrollEnabled &&
                            YES == scv.panGestureRecognizer.enabled) {
                            [self addCurrPanSV:scv];
                        }
                    } else if ([theview isKindOfClass:[UIControl class]]) {
                        if (theview.userInteractionEnabled
                            && [(UIControl *)theview isEnabled]) {
                            [self addCareOtherObj:(id)theview forKey:@"control"];
                        }
                    } else if ([theview isKindOfClass:[UITableViewCell class]]
                               || [theview isKindOfClass:[UICollectionViewCell class]]) {
                        [self addCareOtherObj:(id)theview forKey:@"cell"];
                    } else if (theview.userInteractionEnabled
                               && [theview.nextResponder isKindOfClass:[UINavigationController class]]) {
                        UINavigationController *thenc = (UINavigationController *)theview.nextResponder;
                        if (thenc.interactivePopGestureRecognizer) {
                            if (self.transitionGesDelegate
                                && [self.transitionGesDelegate respondsToSelector:@selector(checkTransitionGes:otherTransitionGes:makeFail:)]) {
                                NSInteger checkst =\
                                [self.transitionGesDelegate checkTransitionGes:self
                                                            otherTransitionGes:thenc.interactivePopGestureRecognizer
                                                                      makeFail:YES];
                                
                                if (2 == checkst) {
                                    [self makeGestureStateCanceledOrFailed];
                                    return;
                                }
                            }
                        }
                        
                        [self addCareOtherObj:(id)theview forKey:@"nc"];
                    }
                }
            }
            
            if (self.touchAr.count == 1) {
                //单点touch开始
                if (!_panInfoAr) {
                    //开启pan记录
                    _panInfoAr = [NSMutableArray new];
                    
                    if ([self isPanBeginSVBounces]) {
                        _beganWithSVBounces = YES;
                    }
                    
                    //不return，继续后面的change流程
                } else {
                    return;
                }
            } else if (self.touchAr.count >= 2) {
                if (!_panInfoAr) {
                    //pan没有触发，直接2点起步。 后续优化写法，这里先补完isPanBeginSVBounces判定
                    if ([self isPanBeginSVBounces]) {
                        _beganWithSVBounces = YES;
                    }
                }
                
                if (!_pinchInfoAr) {
                    _pinchInfoAr = [NSMutableArray new];
                    //不return，继续后面的change流程
                } else {
                    return;
                }
            } else {
                return;
            }
        case UIGestureRecognizerStateChanged: {
            BOOL panchange = NO;
            if (_panInfoAr) {
                UITouch *firsttouch = self.touchAr.firstObject;
                
                //判断是首个touch的变化
                if (firsttouch
                    && [touches containsObject:firsttouch]) {
                    CGPoint locpt = [firsttouch locationInView:self.view];
                    if (_panInfoAr.count > 0 &&
                        CGPointEqualToPoint(_panInfoAr.lastObject.CGRectValue.origin, locpt)) {
                        return;
                    }
                    
                    [_panInfoAr addObject:@((CGRect){locpt, [NSDate date].timeIntervalSince1970, 0})];
                    
                    //最大存储数量限制
                    if (_panInfoAr.count > 9) {
                        [_panInfoAr removeObjectAtIndex:2];
                    }
                    
                    panchange = YES;
                }
            }
            
            BOOL pinchchange = NO;
            if (_pinchInfoAr
                && self.touchAr.count >= 2) {
                UITouch *touch1 = self.touchAr[0];
                UITouch *touch2 = self.touchAr[1];
                if ([touches containsObject:touch1]
                    || [touches containsObject:touch2]) {
                    BOTransitionGesturePinchInfo *pininfo = [BOTransitionGesturePinchInfo pinchInfoWithTouchAr:@[touch1, touch2] containerView:self.view];
                    if (pininfo) {
                        pininfo.tsSinceFirst = pininfo.ts - _pinchInfoAr.firstObject.ts;
                        [_pinchInfoAr addObject:pininfo];
                        if (_pinchInfoAr.count > sf_max_pinchInfo_count) {
                            [_pinchInfoAr removeObjectAtIndex:2];
                        }
                        pinchchange = YES;
                    }
                }
                
            }
            
            if (panchange
                || pinchchange) {
                self.originState = state;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            BOOL panfinish = NO;
            if (_panInfoAr) {
                UITouch *firsttouch = self.touchAr.firstObject;
                
                //判断是首个touch的变化
                if (firsttouch
                    && [touches containsObject:firsttouch]) {
                    
                    CGPoint locpt = [firsttouch locationInView:self.view];
                    [_panInfoAr addObject:@((CGRect){locpt, [NSDate date].timeIntervalSince1970, 0})];
                    
                    if (_panInfoAr.count > 9) {
                        [_panInfoAr removeObjectAtIndex:2];
                    }
                    
                    panfinish = YES;
                }
                
            }
            
            BOOL pinchfinish = NO;
            if (_pinchInfoAr
                && self.touchAr.count >= 2) {
                UITouch *touch1 = self.touchAr[0];
                UITouch *touch2 = self.touchAr[1];
                if ([touches containsObject:touch1]
                    || [touches containsObject:touch2]) {
                    BOTransitionGesturePinchInfo *pininfo = [BOTransitionGesturePinchInfo pinchInfoWithTouchAr:@[touch1, touch2] containerView:self.view];
                    BOTransitionGesturePinchInfo *lastpininfo = _pinchInfoAr.lastObject;
                    if (pininfo && ![pininfo isPointEqual:lastpininfo]) {
                        pininfo.tsSinceFirst = pininfo.ts - _pinchInfoAr.firstObject.ts;
                        [_pinchInfoAr addObject:pininfo];
                        pinchfinish = YES;
                    }
                }
            }
            
            [self.touchAr removeObjectsInArray:touches];
            
            if (self.touchAr.count == 0) {
                self.originState = state;
                [self makeGestureStateCanceledOrFailed];
            } else if (panfinish) {
                //pan结束了，pinch当前也结束了，全部结束
                self.originState = state;
                [self makeGestureStateCanceledOrFailed];
            } else if (pinchfinish) {
                BOOL hastranbegan = (UIGestureRecognizerStateBegan == _transitionGesState
                                     || UIGestureRecognizerStateChanged == _transitionGesState);
                if (hastranbegan) {
                    //pinch转场中，结束手势
                    self.originState = state;
                    [self makeGestureStateCanceledOrFailed];
                } else {
                    //只有pinch结束了
                    [_pinchInfoAr removeAllObjects];
                    _pinchInfoAr = nil;
                }
            } else {
                //都没结束，什么也不用做
            }
            
        }
            break;
        default:
            break;
    }
}

- (CGFloat)obtainPinchVelocity {
    NSInteger pcount = self.pinchInfoAr.count;
    if (pcount <= 1) {
        return 0.0;
    }
    CGFloat lastspace = self.pinchInfoAr.lastObject.space;
    CGFloat lastts = self.pinchInfoAr.lastObject.ts;
    for (NSInteger idx = self.pinchInfoAr.count - 2; idx >= 0; idx--) {
        BOTransitionGesturePinchInfo *infoitem = self.pinchInfoAr[idx];
        CGFloat durts = lastts - infoitem.ts;
        if (durts >= 0.1) {
            return (lastspace - infoitem.space) / durts;
        }
        
        if (pcount >= sf_max_pinchInfo_count
            && idx == 1) {
            //到最大后，取第二个就好了，因为前面可能被裁剪过数据
            break;
        } else if (idx == 0) {
            return (lastspace - infoitem.space) / durts;
        }
    }
    
    return 0.0;
}

- (void)setOriginState:(UIGestureRecognizerState)originState {
    if (_originState != originState
        || UIGestureRecognizerStateChanged == originState) {
        _originState = originState;
        BOOL hastranbegan = (UIGestureRecognizerStateBegan == _transitionGesState
                             || UIGestureRecognizerStateChanged == _transitionGesState);
        
        switch (originState) {
            case UIGestureRecognizerStateBegan: {
                
                if (_needsRecoverWhenTouchDown) {
                    NSNumber *shouldbegin;
                    NSString *gestype = nil;
                    if (self.transitionGesDelegate &&
                        [self.transitionGesDelegate respondsToSelector:@selector(boTransitionGesShouldAndWillBegin:specialMainDirection:subInfo:)]) {
                        UISwipeGestureRecognizerDirection anDir = _lastGesBrief.triggerDirectionInfo.mainDirection;
                        NSDictionary *controldic =\
                        [self.transitionGesDelegate boTransitionGesShouldAndWillBegin:self
                                                                 specialMainDirection:&anDir
                                                                              subInfo:@{@"type": @"needsRecoverWhenTouchDown"}];
                        shouldbegin = [controldic objectForKey:@"shouldBegin"];
                        gestype = [controldic objectForKey:@"gesType"];
                        if (anDir != _lastGesBrief.triggerDirectionInfo.mainDirection) {
                            //recover的时候应该不需要修改，虽然估计用不到，暂保留吧
                            _lastGesBrief.triggerDirectionInfo.subDirection = _lastGesBrief.triggerDirectionInfo.mainDirection;
                            _lastGesBrief.triggerDirectionInfo.mainDirection = anDir;
                        }
                    }
                    
                    if (nil != shouldbegin &&
                        shouldbegin.boolValue) {
                        _initialDirectionInfo = _lastGesBrief.triggerDirectionInfo;
                        _initialDirectionInfo.location = _panInfoAr.lastObject.CGRectValue.origin;
                        _triggerDirectionInfo = _initialDirectionInfo;
//                        [_panInfoAr insertObject:_lastGesBrief.touchBeganVal atIndex:0];
                        
                        _needsRecoverWhenTouchDown = NO;
                        
                        //执行手势冲突策略，自己还活着后，开始转场
                        if ([self mixGesAndExecStrategy]) {
                            self.gesType = gestype;
                            self.transitionGesState = UIGestureRecognizerStateBegan;
                        }
                    } else {
                        _needsRecoverWhenTouchDown = NO;
                    }
                }
            }
                break;
            case UIGestureRecognizerStateChanged: {
                if (!hastranbegan) {
                    [self tryBeginTransitionGesAndMakeInfo];
                } else {
                    self.transitionGesState = UIGestureRecognizerStateChanged;
                    //otherges比如pinch可以将转场打断
                    [self checkOtherGes];
                }
            }
                break;
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled: {
                //如果当前已经是begin，与内部相同变化，ended或者cancelled就可以，如果当前是其它状态，直接重置即可
                if (hastranbegan) {
                    self.transitionGesState = originState;
                    _transitionGesState = UIGestureRecognizerStatePossible;
                } else {
                    _transitionGesState = UIGestureRecognizerStateFailed;
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)saveCurrGesContextAndSetNeedsRecoverWhenTouchDown {
    if (self.panInfoAr.count <= 0) {
        return;
    }
    NSValue *firstptval = self.panInfoAr.firstObject;
    BOTransitionGesSliceInfo briefslice = self.triggerDirectionInfo;
    briefslice.location = firstptval.CGRectValue.origin;
    
    BOTransitionGestureBrief brief = (BOTransitionGestureBrief){
        self.panInfoAr.copy,
        briefslice
    };
    
    _lastGesBrief = brief;
    _needsRecoverWhenTouchDown = YES;
}

- (void)clearSaveContext {
    _needsRecoverWhenTouchDown = NO;
}

- (BOTransitionGesBeganInfo)calculateBeganInfo {
    CGRect boardbounds = self.view.bounds;
    BOTransitionGesBeganInfo beganinfo = (BOTransitionGesBeganInfo){UIEdgeInsetsZero, UIEdgeInsetsZero, CGPointZero, boardbounds};
    if (self.panInfoAr.count >= 2) {
        CGPoint pt1 = self.panInfoAr.firstObject.CGRectValue.origin;
        beganinfo.location = pt1;
        
        beganinfo.marginSpace = UIEdgeInsetsMake(pt1.y - CGRectGetMinY(boardbounds),
                                                 pt1.x - CGRectGetMinX(boardbounds),
                                                 CGRectGetMinY(boardbounds) - pt1.y,
                                                 CGRectGetMaxX(boardbounds) - pt1.x);
        
        CGPoint gesvel = self.initialDirectionInfo.velocity;
        CGFloat fabs_x = fabs(gesvel.x);
        CGFloat fabs_y = fabs(gesvel.y);
        
        CGFloat upweight;
        CGFloat leftweight;
        CGFloat downweight;
        CGFloat rightweight;
        
        if (0 == fabs_x) {
            //横向无速度
            leftweight = 0;
            rightweight = 0;
            
            if (0 == fabs_y) {
                //竖向无速度
                upweight = 0;
                downweight = 0;
            } else {
                //竖向有速度
                if (gesvel.y > 0) {
                    upweight = -99;
                    downweight = 99;
                } else {
                    upweight = 99;
                    downweight = -99;
                }
            }
        } else {
            //横向有速度
            if (0 == fabs_y) {
                //竖向无速度
                upweight = 0;
                downweight = 0;
                
                if (gesvel.x > 0) {
                    leftweight = -99;
                    rightweight = 99;
                } else {
                    leftweight = 99;
                    rightweight = -99;
                }
            } else {
                //竖向有速度
                CGFloat hweight = fabs_x / fabs_y;
                if (gesvel.x > 0) {
                    leftweight = -hweight;
                    rightweight = hweight;
                } else {
                    leftweight = hweight;
                    rightweight = -hweight;
                }
                
                CGFloat vweight = fabs_y / fabs_x;
                if (gesvel.y > 0) {
                    upweight = -vweight;
                    downweight = vweight;
                } else {
                    upweight = vweight;
                    downweight = -vweight;
                }
            }
        }
        
        beganinfo.directionWeight = UIEdgeInsetsMake(upweight, leftweight, downweight, rightweight);
    }
    
    return beganinfo;
}

- (NSNumber *)tryBeginTransitionGesAndMakeInfo {
    BOTransitionGesSliceInfo drinfo = [self generateSliceInfo];
    if (0 == drinfo.mainDirection
        && self.pinchInfoAr.count == 0) {
        //没有方向，没有pinch，什么也不做
        return nil;
    }
    
    //生成pan相关的信息
    BOOL isInitial = (2 == _panInfoAr.count);
    if (isInitial) {
        //初始方向信息
        _initialDirectionInfo = drinfo;
        _isDelayTrigger = NO;
        
        _gesBeganInfo = [self calculateBeganInfo];
    } else {
        _isDelayTrigger = YES;
    }
    
    _triggerDirectionInfo = drinfo;
    
    NSNumber *shouldbegin = nil;
    NSDictionary *mainresdic = [self currPanSVAcceptDirection:drinfo.mainDirection];
    NSString *gestype = nil;
    //询问代理是否开始transition
    if (self.transitionGesDelegate &&
        [self.transitionGesDelegate respondsToSelector:@selector(boTransitionGesShouldAndWillBegin:specialMainDirection:subInfo:)]) {
        UISwipeGestureRecognizerDirection anDir = drinfo.mainDirection;
        NSDictionary *controldic =\
        [self.transitionGesDelegate boTransitionGesShouldAndWillBegin:self
                                                 specialMainDirection:&anDir
                                                              subInfo:@{
            @"otherSVResponse": mainresdic ? : @{}
        }];
        shouldbegin = [controldic objectForKey:@"shouldBegin"];
        gestype = [controldic objectForKey:@"gesType"];
        if (anDir != drinfo.mainDirection) {
            //delegate指定了新的mainDirection
            drinfo.subDirection = drinfo.mainDirection;
            drinfo.mainDirection = anDir;
            _triggerDirectionInfo = drinfo;
        }
    }
    
    NSNumber *hasbeginorfail = nil;
    if (nil != shouldbegin) {
        if (shouldbegin.boolValue) {
            //恢复被手势触发瞬间offset的scrollView
            [self correctAndSaveCurSVOffsetSugDirection:drinfo.mainDirection];
            //执行手势冲突策略，自己还活着后，开始转场
            if ([self mixGesAndExecStrategy]) {
                self.gesType = gestype;
                self.transitionGesState = UIGestureRecognizerStateBegan;
                hasbeginorfail = @(YES);
            } else {
                hasbeginorfail = @(NO);
            }
        } else {
            [self makeGestureStateCanceledOrFailed];
            hasbeginorfail = @(NO);
        }
    } else {
        //本次没有开始转场，如果scrollView进行了bounces响应，也记录为已响应方向
        if (mainresdic) {
            [self addRecordOtherSVRespondedDirection:drinfo.mainDirection infoDic:mainresdic];
        }
        
        NSDictionary *subresdic = [self currPanSVAcceptDirection:drinfo.subDirection];
        if (subresdic) {
            [self addRecordOtherSVRespondedDirection:drinfo.subDirection infoDic:subresdic];
        }
    }
    
    return hasbeginorfail;
}

- (void)checkOtherGes {
    [_otherGesWillExecSimultaneouslyStrategy enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull obj,
                                                                          NSUInteger idx,
                                                                          BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIPinchGestureRecognizer class]]) {
            [self execeSimultaneouslyStrategy:obj makeGesFailedOrCancelled:nil];
        }
    }];
    
}

/*
 return:  YES,执行完后，自己还活着
 NO： 执行完后，自己被杀死了
 */
- (BOOL)execeSimultaneouslyStrategy:(UIGestureRecognizer *)ges makeGesFailedOrCancelled:(BOOL *)makeGesFailedOrCancelled {
    if (UIGestureRecognizerStateFailed == ges.state
        || UIGestureRecognizerStateCancelled == ges.state) {
        return YES;
    }
    
    NSInteger strategy = 0;
    BOOL istran = [BOTransitionGesture isTransitonGes:ges];
    if (istran) {
        if ([self.transitionGesDelegate respondsToSelector:@selector(checkTransitionGes:otherTransitionGes:makeFail:)]) {
            NSInteger spsgy = [self.transitionGesDelegate checkTransitionGes:self
                                                          otherTransitionGes:ges
                                                                    makeFail:NO];
            if (0 != spsgy) {
                strategy = spsgy;
            }
        }
    } else {
        if ([self.gesType isEqualToString:@"pinch"]) {
            
        } else {
            //如果本次ges是pan类型，那其它的缩放手势优先响应
            if ([ges isKindOfClass:[UIPinchGestureRecognizer class]]) {
                if (ges.state == UIGestureRecognizerStateBegan
                    || ges.state == UIGestureRecognizerStateChanged) {
                    CGRect firstptinfo = _panInfoAr.firstObject.CGRectValue;
                    CGFloat firstptts = firstptinfo.size.width;
                    CGFloat durts = [NSDate date].timeIntervalSince1970 - firstptts;
                    //等待时间内内才允许再次将本手势fail，超过后就算了，用户已经滑了一会儿了
                    if (durts < sf_ges_conflict_wait_time) {
                        strategy = 2;
                    } else {
                        strategy = 4;
                    }
                }
            } else if ([ges isKindOfClass:[UIPanGestureRecognizer class]]
                       && [ges.view isKindOfClass:[UIScrollView class]]) {
                //其它UIScrollView的pan，暂不将其fail，因为手势又回来时，还有回复scrolView继续滑动
    //            strategy = 4;
            }
        }
        
        if ([self.transitionGesDelegate boTransitionGRStrategyForGes:self otherGes:ges]) {
            NSInteger spsgy = [self.transitionGesDelegate boTransitionGRStrategyForGes:self
                                                                              otherGes:ges];
            if (0 != spsgy) {
                strategy = spsgy;
            }
        }
    }
    
    BOOL sfalive = YES;
    BOOL killges = NO;
    
    switch (strategy) {
        case 1: {
            killges = [BOTransitionGesture tryMakeGesFail:ges
                                                    byGes:self
                                                    force:istran];
        }
            break;
        case 2: {
            [self makeGestureStateCanceledOrFailed];
            sfalive = NO;
        }
            break;
        case 4: {
            killges = [BOTransitionGesture tryMakeGesFail:ges
                                                    byGes:self
                                                    force:YES];
        }
            break;
        default:
            break;
    }
    
    if (makeGesFailedOrCancelled) {
        *makeGesFailedOrCancelled = killges;
    }
    
    return sfalive;
}

/*
 混合计算手势、执行冲突策略
 return: self是否还活着
 */
- (BOOL)mixGesAndExecStrategy {
    //执行手势冲突处理
    __block BOOL hasFailed = NO;
    [_otherGesWillExecSimultaneouslyStrategy enumerateObjectsUsingBlock:^(UIGestureRecognizer * _Nonnull obj,
                                                                          NSUInteger idx,
                                                                          BOOL * _Nonnull stop) {
        if (![self execeSimultaneouslyStrategy:obj makeGesFailedOrCancelled:nil]) {
            hasFailed = YES;
        }
    }];
    
    if (hasFailed) {
        return NO;
    }
    
    __block BOOL hasDrag = NO;
    [_currPanScrollVAr enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isDragging || obj.isTracking) {
            hasDrag = YES;
            switch (obj.panGestureRecognizer.state) {
                case UIGestureRecognizerStatePossible:
                case UIGestureRecognizerStateBegan:
                case UIGestureRecognizerStateChanged:
                    if (![_otherGesWillExecSimultaneouslyStrategy containsObject:obj.panGestureRecognizer]) {
                        BOOL isfc = NO;
                        BOOL failedsf = [self execeSimultaneouslyStrategy:obj.panGestureRecognizer makeGesFailedOrCancelled:&isfc];
                        if (failedsf) {
                            hasFailed = YES;
                        }
                        if (isfc) {
                            hasDrag = NO;
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    }];
    
    if (!hasDrag
        && ([self careOtherArForKey:@"cell"].count > 0
            || [self careOtherArForKey:@"control"].count > 0)) {
        /*
         有control时暂时借用系统的能力时uicontrol停止响应失效
         */
        self.state = UIGestureRecognizerStateBegan;
    }
    
    if (hasFailed) {
        return NO;
    } else {
        return YES;
    }
}

- (void)setTransitionGesState:(UIGestureRecognizerState)transitionGesState {
    if (_transitionGesState != transitionGesState
        || UIGestureRecognizerStateChanged == transitionGesState
        ) {
        _transitionGesState = transitionGesState;
        
        if (self.transitionGesDelegate &&
            [self.transitionGesDelegate respondsToSelector:@selector(boTransitionGesStateDidChange:)]) {
            [self.transitionGesDelegate boTransitionGesStateDidChange:self];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (void)addGesWillExecSimultaneouslyStrategy:(UIGestureRecognizer *)ges {
    if (self == ges) {
        return;
    }
    if (!_otherGesWillExecSimultaneouslyStrategy) {
        _otherGesWillExecSimultaneouslyStrategy = [NSMutableArray new];
    }
    if (![_otherGesWillExecSimultaneouslyStrategy containsObject:ges]) {
        [_otherGesWillExecSimultaneouslyStrategy addObject:ges];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self
        && otherGestureRecognizer != gestureRecognizer) {
        BOOL shouldfailsf = NO;
        
        if ([BOTransitionGesture isTransitonGes:otherGestureRecognizer]) {
            if (self.transitionGesDelegate
                && [self.transitionGesDelegate respondsToSelector:@selector(checkTransitionGes:otherTransitionGes:makeFail:)]) {
                NSInteger checkst = [self.transitionGesDelegate checkTransitionGes:self
                                                                otherTransitionGes:otherGestureRecognizer
                                                                          makeFail:YES];
                
                if (2 == checkst) {
                    shouldfailsf = YES;
                }
            }
        } else {
            if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
                shouldfailsf = YES;
            }
        }
        
        if (UIGestureRecognizerStateBegan == _transitionGesState || UIGestureRecognizerStateChanged == _transitionGesState) {
            [self execeSimultaneouslyStrategy:otherGestureRecognizer makeGesFailedOrCancelled:nil];
        } else {
            [self addGesWillExecSimultaneouslyStrategy:otherGestureRecognizer];
        }
        
        return shouldfailsf;
    } else {
        return NO;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self
        && otherGestureRecognizer != gestureRecognizer) {
        BOOL shouldfailog = NO;
        if ([BOTransitionGesture isTransitonGes:otherGestureRecognizer]) {
            if (self.transitionGesDelegate
                && [self.transitionGesDelegate respondsToSelector:@selector(checkTransitionGes:otherTransitionGes:makeFail:)]) {
                NSInteger checkst = [self.transitionGesDelegate checkTransitionGes:self
                                                                otherTransitionGes:otherGestureRecognizer
                                                                          makeFail:YES];
                
                if (1 == checkst) {
                    shouldfailog = YES;
                }
            }
        } else {
            if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
                shouldfailog = NO;
            }
        }
        
        if (UIGestureRecognizerStateBegan == _transitionGesState || UIGestureRecognizerStateChanged == _transitionGesState) {
            [self execeSimultaneouslyStrategy:otherGestureRecognizer makeGesFailedOrCancelled:nil];
        } else {
            [self addGesWillExecSimultaneouslyStrategy:otherGestureRecognizer];
        }
        
        return shouldfailog;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer != self
        || otherGestureRecognizer == gestureRecognizer) {
        return NO;
    }
    
    BOOL shouldsim = YES;
    if ([BOTransitionGesture isTransitonGes:otherGestureRecognizer]) {
        shouldsim = NO;
    } else {
        if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
            shouldsim = NO;
        }
    }
    
    if (UIGestureRecognizerStateBegan == _transitionGesState || UIGestureRecognizerStateChanged == _transitionGesState) {
        [self execeSimultaneouslyStrategy:otherGestureRecognizer makeGesFailedOrCancelled:nil];
    } else {
        [self addGesWillExecSimultaneouslyStrategy:gestureRecognizer];
    }
    
    return shouldsim;
}

#pragma mark - 生成外部手势状态
- (NSMutableDictionary<NSString *,NSMutableArray *> *)careOtherDic {
    if (!_careOtherDic) {
        _careOtherDic = [NSMutableDictionary new];
    }
    return _careOtherDic;;
}

- (void)addCareOtherObj:(NSObject *)obj forKey:(NSString *)key {
    if (!obj
        || !key) {
        return;
    }
    
    NSMutableArray *muar = [self.careOtherDic objectForKey:key];
    if (!muar) {
        muar = [NSMutableArray new];
        [self.careOtherDic setObject:muar forKey:key];
    }
    if (![muar containsObject:obj]) {
        [muar addObject:obj];
    }
}

- (NSArray *)careOtherArForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    return [self.careOtherDic objectForKey:key];
}

/*
 有的scrollView会在开始滑动的一瞬被移动一些offset，开始转场后，复位其位置
 */
- (void)correctAndSaveCurSVOffsetSugDirection:(UISwipeGestureRecognizerDirection)direction {
    if (_currPanScrollVAr.count > 0) {
        if (!_currPanScrollVSavOffsetAr) {
            _currPanScrollVSavOffsetAr = [NSMutableArray new];
        }
        [_currPanScrollVSavOffsetAr removeAllObjects];
        [_currPanScrollVAr enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIEdgeInsets insets = sf_common_contentInset(obj);
            CGSize contentsz = obj.contentSize;
            CGPoint offset = obj.contentOffset;
            CGSize boundsz = obj.bounds.size;
            CGPoint shouldos = offset;
            switch (direction) {
                case UISwipeGestureRecognizerDirectionUp: {
                    CGFloat maxy = MAX(-insets.top, (contentsz.height + insets.bottom - boundsz.height));
                    if (shouldos.y > maxy) {
                        shouldos.y = maxy;
                    }
                }
                    break;
                case UISwipeGestureRecognizerDirectionDown: {
                    CGFloat miny = -insets.top;
                    if (shouldos.y < miny) {
                        shouldos.y = miny;
                    }
                }
                    break;
                case UISwipeGestureRecognizerDirectionLeft: {
                    CGFloat maxx = MAX(-insets.left, (contentsz.width + insets.right - boundsz.width));
                    if (shouldos.x > maxx) {
                        shouldos.x = maxx;
                    }
                }
                    break;
                case UISwipeGestureRecognizerDirectionRight: {
                    CGFloat minx = -insets.left;
                    if (shouldos.x < minx) {
                        shouldos.x = minx;
                    }
                }
                    break;
                default:
                    break;
            }
            
            if (!CGPointEqualToPoint(offset, shouldos)) {
                [obj setContentOffset:shouldos];
            }
            
            [_currPanScrollVSavOffsetAr addObject:[NSValue valueWithCGPoint:obj.contentOffset]];
        }];
    } else {
        [_currPanScrollVSavOffsetAr removeAllObjects];
    }
}

- (void)recoverCurSVOffset {
    if (_currPanScrollVAr.count > 0 &&
        _currPanScrollVAr.count == _currPanScrollVSavOffsetAr.count) {
        [_currPanScrollVAr enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint theos = _currPanScrollVSavOffsetAr[idx].CGPointValue;
            if (UIGestureRecognizerStateChanged == obj.panGestureRecognizer.state
                && !CGPointEqualToPoint(obj.contentOffset, theos)) {
                [obj setContentOffset:theos];
            }
        }];
    }
}

- (void)addCurrPanSV:(UIScrollView *)sv {
    if (!_currPanScrollVAr) {
        _currPanScrollVAr = [NSMutableArray new];
    }
    
    if (![_currPanScrollVAr containsObject:sv]) {
        [sv.panGestureRecognizer addTarget:self action:@selector(boTransitionOtherSVOnPan:)];
        [_currPanScrollVAr addObject:sv];
    }
}

- (void)clearCurrSVRecord {
    [_currPanScrollVAr enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.panGestureRecognizer removeTarget:self action:@selector(boTransitionOtherSVOnPan:)];
    }];
    [_currPanScrollVAr removeAllObjects];
    _currPanScrollVAr = nil;
    [_currPanScrollVSavOffsetAr removeAllObjects];
    _currPanScrollVSavOffsetAr = nil;
    [_otherSVRespondedDirectionRecord removeAllObjects];
    _otherSVRespondedDirectionRecord = nil;
    
    _isDelayTrigger = NO;
}

/*
 gesMes: 1可能会触发/2已经明确触发了
 */
- (void)addRecordOtherSVRespondedDirection:(UISwipeGestureRecognizerDirection)direction
                                   infoDic:(NSDictionary *)infoDic {
    if (!_otherSVRespondedDirectionRecord) {
        _otherSVRespondedDirectionRecord = @{}.mutableCopy;
    }
    
    NSMutableDictionary *directioninfodic = _otherSVRespondedDirectionRecord[@(direction)];
    if (!directioninfodic) {
        directioninfodic = @{}.mutableCopy;
        _otherSVRespondedDirectionRecord[@(direction)] = directioninfodic;
        
        [directioninfodic addEntriesFromDictionary:infoDic];
    } else {
        CGPoint lastpt = CGPointZero;
        NSValue *lastptval = directioninfodic[@"info"];
        if (nil != lastptval) {
            lastpt = lastptval.CGPointValue;
        }
        
        NSHashTable *lastgesar = directioninfodic[@"gesAr"];
        if (!lastgesar) {
            //容错
            lastgesar = [NSHashTable weakObjectsHashTable];
            directioninfodic[@"gesAr"] = lastgesar;
        }
        
        CGPoint currpt = CGPointZero;
        NSValue *currptval = infoDic[@"info"];
        if (nil != currptval) {
            currpt = currptval.CGPointValue;
        }
        
        BOOL bigger = NO;
        if (currpt.y > lastpt.y) {
            bigger = YES;
        } else if (currpt.y == lastpt.y
                   && currpt.x > lastpt.x) {
            bigger = YES;
        }
        
        if (bigger) {
            directioninfodic[@"info"] = @(currpt);
            
            NSHashTable *lastgesar = directioninfodic[@"gesAr"];
            NSHashTable *thegesar = infoDic[@"gesAr"];
            if (thegesar.count > 0) {
                if (!lastgesar) {
                    //容错
                    lastgesar = [NSHashTable weakObjectsHashTable];
                    directioninfodic[@"gesAr"] = lastgesar;
                }
                
                [[thegesar allObjects] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![lastgesar containsObject:obj]) {
                        [lastgesar addObject:obj];
                    }
                }];
            }
        }
    }
}

- (void)makeGestureStateCanceledOrFailed {
    self.state = UIGestureRecognizerStateFailed;
    
    switch (self.transitionGesState) {
        case UIGestureRecognizerStatePossible:
            _transitionGesState = UIGestureRecognizerStateFailed;
            break;
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            self.transitionGesState = UIGestureRecognizerStateCancelled;
            break;
        default:
            break;
    }
    //主动reset一下，清空内容，防止后续的touchmove还继续触发尝试启动手势
    [self innerReset];
}

/*
 其它scrollView的触发，
 */
- (void)boTransitionOtherSVOnPan:(UIPanGestureRecognizer *)panGes {
    
    BOOL hastranbegan = (UIGestureRecognizerStateBegan == _transitionGesState
                         || UIGestureRecognizerStateChanged == _transitionGesState);
    
    switch (panGes.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            if (!hastranbegan) {
                [self tryBeginTransitionGesAndMakeInfo];
            } else {
                [self recoverCurSVOffset];
            }
        }
            break;
        default: {
            
        }
            break;
    }
    
}

#pragma mark - helper func

- (BOTransitionGesSliceInfo)generateSliceInfo {
    CGPoint velocity = [self velocityInCurrView];
    
    UISwipeGestureRecognizerDirection vdi = 0;
    if (velocity.y > 0) {
        vdi = UISwipeGestureRecognizerDirectionDown;
    } else if (velocity.y < 0) {
        vdi = UISwipeGestureRecognizerDirectionUp;
    }
    
    UISwipeGestureRecognizerDirection hdi = 0;
    if (velocity.x > 0) {
        hdi = UISwipeGestureRecognizerDirectionRight;
    } else if (velocity.x < 0) {
        hdi = UISwipeGestureRecognizerDirectionLeft;
    }
    
    UISwipeGestureRecognizerDirection maindi = 0;
    UISwipeGestureRecognizerDirection subdi = 0;
    BOOL v = (fabs(velocity.y) > fabs(velocity.x));
    if (v) {
        maindi = vdi;
        subdi = hdi;
    } else {
        maindi = hdi;
        subdi = vdi;
    }
    
    CGPoint loc = [self locationInView:self.view];
    return (BOTransitionGesSliceInfo){maindi, subdi, velocity, loc};
}

/*
 一次只支持传一个方向
 {x, y}
 x:
 0 不能滑动 不能bounces
 1 for  bounces
 2 normal scroll
 
 y:
 1 手势是可能的状态
 2 手势明确启动了
 
 info: @(CGPoint)
 gesAr: NSHashTable<UIGestureRecognizer>
 
 */
- (NSDictionary *)currPanSVAcceptDirection:(UISwipeGestureRecognizerDirection)gesDirection {
    if (0 == gesDirection) {
        return nil;
    }
    
    if (_currPanScrollVAr.count <= 0) {
        return nil;
    }
    
    CGFloat one_pxiel = 1.f / self.view.window.screen.scale;
    __block CGPoint totalmes = CGPointZero;
    __block UIGestureRecognizer *theges = nil;
    [_currPanScrollVAr enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL gesvalid = NO;
        BOOL gescertain = NO;
        switch (obj.panGestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:
            case UIGestureRecognizerStateChanged:
                gescertain = YES;
            case UIGestureRecognizerStatePossible:
                gesvalid = YES;
                break;
            default:
                break;
        }
        
        if (!gesvalid) {
            return;
        }
        
        CGPoint gesmes = (CGPoint){0, (gescertain ? 2 : 1)};
        
        UIEdgeInsets insets = sf_common_contentInset(obj);
        CGSize contentsz = obj.contentSize;
        CGPoint offset = obj.contentOffset;
        CGSize boundsz = obj.bounds.size;
        switch (gesDirection) {
            case UISwipeGestureRecognizerDirectionUp:
                if (contentsz.height + insets.top + insets.bottom > boundsz.height + one_pxiel) {
                    //上下能正常滚动
                    if ((offset.y + boundsz.height + one_pxiel) < (contentsz.height + insets.bottom)) {
                        //能正常响应
                        gesmes.x = 2;
                    } else {
                        //不能响应了，需要bounces
                        if (obj.bounces) {
                            gesmes.x = 1;
                        } else {
                            //不能响应
                        }
                    }
                } else {
                    //上下不能正常滚动
                    if (obj.bounces && obj.alwaysBounceVertical) {
                        //可bounces
                        if (offset.y + one_pxiel < -insets.top) {
                            //在头部bounces中，向上滑是正常恢复的方向，判定为正常滑动
                            gesmes.x = 2;
                        } else {
                            //正常状态或底部bounces状态，向上滑是bounces行为
                            gesmes.x = 1;
                        }
                    } else {
                        //不可bounces，什么也不能响应
                    }
                }
                break;
            case UISwipeGestureRecognizerDirectionDown:
                if (contentsz.height + insets.top + insets.bottom > boundsz.height + one_pxiel) {
                    //上下能正常滚动
                    if (offset.y > -insets.top + one_pxiel) {
                        //能正常响应
                        gesmes.x = 2;
                    } else {
                        //不能响应了，需要bounces
                        if (obj.bounces) {
                            gesmes.x = 1;
                        } else {
                            //不能响应
                        }
                    }
                } else {
                    //上下不能正常滚动
                    if (obj.bounces && obj.alwaysBounceVertical) {
                        //可bounces
                        if (offset.y > -insets.top + one_pxiel) {
                            //在底部bounces中，向下滑是正常恢复的方向，判定为正常滑动
                            gesmes.x = 2;
                        } else {
                            //正常状态或头部bounces状态，向下滑是bounces行为
                            gesmes.x = 1;
                        }
                    } else {
                        //不可bounces，什么也不能响应
                    }
                }
                break;
            case UISwipeGestureRecognizerDirectionLeft:
                if (contentsz.width + insets.left + insets.right > boundsz.width + one_pxiel) {
                    //左右能正常滚动
                    if ((offset.x + boundsz.width) < (contentsz.width + insets.right - one_pxiel)) {
                        //能正常响应
                        gesmes.x = 2;
                    } else {
                        //不能响应了，需要bounces
                        if (obj.bounces) {
                            gesmes.x = 1;
                        } else {
                            //不能响应
                        }
                    }
                } else {
                    //左右不能正常滚动
                    if (obj.bounces && obj.alwaysBounceHorizontal) {
                        //可bounces
                        if (offset.x + one_pxiel < -insets.left) {
                            //在左侧bounces中，向左滑是正常恢复的方向，判定为正常滑动
                            gesmes.x = 2;
                        } else {
                            //正常状态或底部bounces状态，向上滑是bounces行为
                            gesmes.x = 1;
                        }
                    } else {
                        //不可bounces，什么也不能响应
                    }
                }
                break;
            case UISwipeGestureRecognizerDirectionRight:
                if (contentsz.width + insets.left + insets.right > boundsz.width + one_pxiel) {
                    //左右能正常滚动
                    if (offset.x > -insets.left + one_pxiel) {
                        //能正常响应
                        gesmes.x = 2;
                    } else {
                        //不能响应了，需要bounces
                        if (obj.bounces) {
                            gesmes.x = 1;
                        } else {
                            //不能响应
                        }
                    }
                } else {
                    //左右不能正常滚动
                    if (obj.bounces && obj.alwaysBounceHorizontal) {
                        //可bounces
                        if (offset.x > -insets.left + one_pxiel) {
                            //在左部bounces中，向右滑是正常恢复的方向，判定为正常滑动
                            gesmes.x = 2;
                        } else {
                            //正常状态或头部bounces状态，向下滑是bounces行为
                            gesmes.x = 1;
                        }
                    } else {
                        //不可bounces，什么也不能响应
                    }
                }
                break;
            default:
                break;
        }
        
        if (gesmes.y > totalmes.y) {
            totalmes = gesmes;
            theges = obj.panGestureRecognizer;
        } else if (gesmes.y == totalmes.y
                   && gesmes.x > totalmes.x) {
            totalmes = gesmes;
            theges = obj.panGestureRecognizer;
        }
    }];
    
    if (theges) {
        NSHashTable *gesar = [NSHashTable weakObjectsHashTable];
        [gesar addObject:theges];
        return @{
            @"info": @(totalmes),
            @"gesAr": gesar
        };
    }
    
    return nil;
}

- (BOOL)isPanBeginSVBounces {
    if (_currPanScrollVAr.count <= 0) {
        return NO;
    }
    
    CGFloat onepixel = (1.f / [UIScreen mainScreen].scale);
    CGPoint movvel = CGPointZero;
//    if (self.panInfoAr.count > 1) {
//        CGPoint pt1 = self.panInfoAr[0].CGRectValue.origin;
//        CGPoint pt2 = self.panInfoAr[1].CGRectValue.origin;
//        movvel.x = pt2.x - pt1.x;
//        movvel.y = pt2.y - pt1.y;
//    }
    __block BOOL hasbounces = NO;
    [_currPanScrollVAr enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIEdgeInsets insets = sf_common_contentInset(obj);
        CGSize contentsz = obj.contentSize;
        CGPoint offset = obj.contentOffset;
        CGSize boundsz = obj.bounds.size;
        if (obj.bounces) {
            if (((contentsz.height + insets.top + insets.bottom) > boundsz.height - onepixel)
                && ((offset.y + boundsz.height - movvel.y)
                    >
                    (contentsz.height + insets.bottom + onepixel))) {
                hasbounces = YES;
            } else if (offset.y - movvel.y
                       <
                       (-insets.top - onepixel)) {
                hasbounces = YES;
            } else if (((contentsz.width + insets.left + insets.right) > boundsz.width - onepixel)
                       &&
                       ((offset.x + boundsz.width - movvel.x) >
                        (contentsz.width + insets.right + onepixel))) {
                hasbounces = YES;
            } else if (offset.x - movvel.x
                       <
                       (-insets.left - onepixel)) {
                hasbounces = YES;
            }
            
            if (hasbounces) {
                *stop = YES;
            }
        }
        
    }];
    
    return hasbounces;
}

- (void)insertBeganPt:(CGPoint)beganPt {
    [_panInfoAr insertObject:@((CGRect){beganPt, CGSizeZero}) atIndex:0];
}

+ (BOOL)tryMakeGesFail:(UIGestureRecognizer *)gesShouldFail
                 byGes:(UIGestureRecognizer *)ges
                 force:(BOOL)force {
    BOOL shouldSimultaneously = NO;
    if (!force) {
        if (gesShouldFail.delegate &&
            [gesShouldFail.delegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
            shouldSimultaneously = [gesShouldFail.delegate gestureRecognizer:gesShouldFail
                          shouldRecognizeSimultaneouslyWithGestureRecognizer:ges];
        }
    }
    
    if (force
        || (!shouldSimultaneously
            && [gesShouldFail canBePreventedByGestureRecognizer:ges])) {
        switch (gesShouldFail.state) {
            case UIGestureRecognizerStatePossible:
                gesShouldFail.state = UIGestureRecognizerStateFailed;
                break;
            case UIGestureRecognizerStateBegan:
            case UIGestureRecognizerStateChanged:
                gesShouldFail.state = UIGestureRecognizerStateCancelled;
                break;
            default:
                break;
        }
        
        return YES;
    }
    
    return NO;
}

+ (NSInteger)isTransitonGes:(UIGestureRecognizer *)ges {
    UIResponder *vnres = ges.view.nextResponder;
    if ([vnres isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)vnres;
        if (nc.interactivePopGestureRecognizer == ges) {
            return 1;
        } else if ([ges isKindOfClass:[BOTransitionGesture class]]) {
            return 2;
        }
    }
    
    //对应present的情况
    if ([ges isKindOfClass:[BOTransitionGesture class]]) {
        return 2;
    }
    
    return 0;
}

@end
