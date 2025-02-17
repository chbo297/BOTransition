//
//  BOTransitionEffectAndroidStyle1Imp.m
//  BOTransitionDemo
//
//  Created by bo on 2022/12/5.
//

#import "BOTransitionEffectAndroidStyle1Imp.h"
#import "BOTransitioning.h"
#import "BOTransitionEffectMovingImp.h"

@interface BOTransitionEffectAndroidStyle1ImpEffectView : UIView

@property (nonatomic, assign) CGPoint currPt;
@property (nonatomic, assign) CGFloat percentComplete;

@property (nonatomic, assign) CGFloat processRate;
@property (nonatomic, assign) CGFloat drawProcessRate;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval dlStartTs;

@property (nonatomic, assign) NSTimeInterval ani_speed;

@property (nonatomic, copy) void (^completionBlock)(void);

@end

@implementation BOTransitionEffectAndroidStyle1ImpEffectView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (CGFloat)rateLength:(CGFloat)length cur:(CGFloat)cur pow:(CGFloat)pow {
    if (cur <= 0) {
        return 0;
    } else if (cur < length) {
        return powf(cur / length, pow);
    } else {
        return 1;
    }
}

- (void)drawRect:(CGRect)rect {
    CGFloat maxcirclew = 36;
    
    CGFloat height = 300;
    CGFloat halfheight = height / 2.f;
    CGFloat margincontrollength = 60;
    CGFloat margincontrolx = maxcirclew * self.drawProcessRate * 0.2;
    CGFloat centercontrollength = 48 + (1.f - self.drawProcessRate) * 12.f;
    
    CGFloat maxboundsy = CGRectGetMaxY(self.bounds);
    
    CGFloat topx = maxcirclew * self.drawProcessRate;
    CGFloat topy = self.currPt.y;
    CGFloat offsetrate = 0;
    if (topy < halfheight) {
        offsetrate = [self rateLength:height
                                  cur:halfheight - topy
                                  pow:1.f];
        topy = halfheight - (offsetrate * halfheight);
    } else if (topy > maxboundsy - halfheight) {
        offsetrate = [self rateLength:height
                                  cur:topy - (maxboundsy - halfheight)
                                  pow:1.f];
        topy = maxboundsy - halfheight + (offsetrate * halfheight);
    }
    
    if (offsetrate > 0) {
        centercontrollength -= 32.f * offsetrate;
    }
    
    CGPoint apt = CGPointMake(0, topy - halfheight);
    CGPoint bpt = CGPointMake(0, topy + halfheight);
    CGFloat controloffset = 0;
    if (apt.y < 0) {
        controloffset = apt.y * 0.6;
        apt.y = 0;
        bpt.y = height;
    } else if (bpt.y > maxboundsy) {
        controloffset = (bpt.y - maxboundsy) * 0.6;
        bpt.y = maxboundsy;
        apt.y = bpt.y - height;
    }
    
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:apt];
    [path1 addCurveToPoint:CGPointMake(topx, topy)
             controlPoint1:CGPointMake(margincontrolx, apt.y + margincontrollength + controloffset)
             controlPoint2:CGPointMake(topx, topy - centercontrollength)];
    [path1 addCurveToPoint:bpt
             controlPoint1:CGPointMake(topx, topy + centercontrollength)
             controlPoint2:CGPointMake(margincontrolx, bpt.y - margincontrollength + controloffset)];
    
    [path1 addLineToPoint:apt];
    [[UIColor colorWithWhite:0 alpha:0.2] setFill];
    [path1 fill];
    
    CGFloat arrowelew = 8.f;
    CGFloat arrowcenterx = topx - MAX(10 + arrowelew / 2.f, topx / 2.f);
    CGFloat arrowalpha = pow(self.drawProcessRate, 0.5);
    UIBezierPath *patharrow = [UIBezierPath bezierPath];
    
    CGFloat arrowminx = arrowcenterx - arrowelew / 2.f;
    [patharrow moveToPoint:CGPointMake(arrowminx + arrowelew, topy - arrowelew)];
    [patharrow addLineToPoint:CGPointMake(arrowminx, topy)];
    [patharrow addLineToPoint:CGPointMake(arrowminx + arrowelew, topy + arrowelew)];
    [patharrow setLineCapStyle:kCGLineCapRound];
    [patharrow setLineJoinStyle:kCGLineJoinRound];
    [patharrow setLineWidth:4];
    [[UIColor colorWithWhite:1 alpha:arrowalpha] setStroke];
    [patharrow stroke];
    
}

- (void)setCurrPt:(CGPoint)currPt {
    
    currPt.x = MAX(currPt.x, 0);
    
    CGFloat maxprocessx = self.bounds.size.width * 0.4;
    self.processRate = [self rateLength:maxprocessx
                                    cur:currPt.x
                                    pow:0.6];
    self.drawProcessRate = self.processRate;
    
//    currPt.x = MIN(currPt.x, 38);
    _currPt = currPt;
    
//    if (!_displayLink) {
//        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
//        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop]
//                           forMode:NSRunLoopCommonModes];
//        _dlStartTs = [NSDate date].timeIntervalSinceReferenceDate;
//    }
    [self setNeedsDisplay];
}

- (void)onDisplayLink:(CADisplayLink *)dl {
    if (!_displayLink) {
        return;
    }
    
    CGFloat thespeed = MAX((2.f * self.ani_speed * fabs(self.processRate - self.drawProcessRate)), 2.f);
    if (self.processRate > self.drawProcessRate) {
        self.drawProcessRate = MIN(self.drawProcessRate + dl.duration * thespeed, self.processRate);
    } else {
        self.drawProcessRate = MAX(self.drawProcessRate - dl.duration * thespeed, self.processRate);
    }
    
    self.drawProcessRate = MAX(self.drawProcessRate, 0);
    [self setNeedsDisplay];
    
    if (fabs(self.processRate - self.drawProcessRate) <= 0.02) {
        [_displayLink invalidate];
        _displayLink = nil;
        
        if (_completionBlock) {
            _completionBlock();
            _completionBlock = nil;
        }
    }
}

- (void)completion:(BOOL)finish completion:(void (^)(void))completion {
    _completionBlock = completion;
    self.processRate = 0;
    
    if (finish) {
        self.ani_speed = 12.5454f;
    } else {
        self.ani_speed = 5.5454f;
    }
    
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
        _dlStartTs = [NSDate date].timeIntervalSinceReferenceDate;
    }
}

@end

@interface BOTransitionEffectAndroidStyle1Imp ()

@property (nonatomic, strong) BOTransitionEffectMovingImp *effectMoving;

@end

@implementation BOTransitionEffectAndroidStyle1Imp

- (BOTransitionEffectMovingImp *)effectMoving {
    if (!_effectMoving) {
        _effectMoving = [[BOTransitionEffectMovingImp alloc] init];
    }
    return _effectMoving;
}

- (NSDictionary *)defaultConfigInfo {
    return @{
        @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionRight),
        @"direction": @(UIRectEdgeRight),
    };
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
    
    [self.effectMoving bo_transitioning:transitioning
                         prepareForStep:step
                         transitionInfo:transitionInfo
                               elements:elements
                                subInfo:subInfo];
    //入场时，默认effectMoving即可，出场时才用android手势特效
    if (transitioning.transitionAct != BOTransitionActMoveOut
        || !transitioning.triggerInteractiveTransitioning) {
        return;
    }
    
    switch (step) {
        case BOTransitionStepInstallElements: {
            //让moving特效停留在0，就是未移动的初始状态
            [elements enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (BOTransitionElementTypeBoard == obj.elementType) {
                    obj.innerPercentWithTransitionPercent = ^CGFloat(CGFloat percent) {
                        return 0;
                    };
                    *stop = YES;
                }
            }];
            
            BOTransitionElement *adele = [BOTransitionElement elementWithType:BOTransitionElementTypeNormal];
            adele.transitionView = [BOTransitionEffectAndroidStyle1ImpEffectView new];
            adele.autoAddAndRemoveTransitionView = 30;
            [adele addToStep:BOTransitionStepTransitioning
                       block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                if (transitioning.triggerInteractiveTransitioning) {
                    BOTransitionEffectAndroidStyle1ImpEffectView *androideffectview = (id)transitionElement.transitionView;
                    if ([androideffectview isKindOfClass:[BOTransitionEffectAndroidStyle1ImpEffectView class]]) {
                        androideffectview.percentComplete = transitionInfo.percentComplete;
                        androideffectview.currPt = [transitioning.transitionGes locationInView:androideffectview];
                    }
                }
            }];
            
            [adele addToStep:BOTransitionStepInteractiveEnd
                       block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
                BOTransitionEffectAndroidStyle1ImpEffectView *androideffectview = (id)transitionElement.transitionView;
                if ([androideffectview isKindOfClass:[BOTransitionEffectAndroidStyle1ImpEffectView class]]) {
                    NSNumber *finish = [subInfo objectForKey:@"finish"];
                    BOOL isfinish = NO;
                    if (nil != finish) {
                        isfinish = finish.boolValue;
                    }
                    [androideffectview completion:isfinish completion:^{
                        
                    }];
                }
            }];
            
            //让moving特效停留在0，就是未移动的初始状态
            [adele addToStep:BOTransitionStepWillFinish | BOTransitionStepWillCancel
                       block:^(BOTransitioning * _Nonnull blockTrans,
                               BOTransitionStep step,
                               BOTransitionElement * _Nonnull transitionElement,
                               BOTransitionInfo transitionInfo,
                               NSDictionary * _Nullable subInfo) {
                [elements enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (BOTransitionElementTypeBoard == obj.elementType) {
                        obj.innerPercentWithTransitionPercent = nil;
                        *stop = YES;
                    }
                }];
            }];
            
            
            
            [elements addObject:adele];
        }
            break;
        default:
            break;
    }
    
}

@end
