//
//  BODisplayTouchPoint.m
//  TEUIUse
//
//  Created by bo on 2019/7/11.
//  Copyright © 2019 bo. All rights reserved.
//

#import "BODisplayTouchPoint.h"
#import <objc/runtime.h>

@interface BODisplayTouchGesRG : UIGestureRecognizer <UIGestureRecognizerDelegate>

@property (nonatomic, copy) void (^didChange)(CGPoint pt, UIGestureRecognizerState state);

@property (nonatomic, strong) UITouch *currTouch;

@end

@implementation BODisplayTouchGesRG

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.delaysTouchesBegan = NO;
        self.delaysTouchesEnded = NO;
//        self.cancelsTouchesInView = NO;
        self.delegate = self;
//        self.state = UIGestureRecognizerStateChanged;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

//- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
//    return NO;
//}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (!_currTouch) {
        _currTouch = [touches anyObject];
        [self makeTouche:_currTouch stateDidChange:UIGestureRecognizerStateBegan];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (_currTouch
        && [touches containsObject:_currTouch]) {
        [self makeTouche:_currTouch stateDidChange:UIGestureRecognizerStateChanged];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (_currTouch
        && ([touches containsObject:_currTouch] || 0 == touches.count)) {
        [self makeTouche:_currTouch stateDidChange:UIGestureRecognizerStateEnded];
        _currTouch = nil;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (_currTouch
        && ([touches containsObject:_currTouch] || 0 == touches.count)) {
        [self makeTouche:_currTouch stateDidChange:UIGestureRecognizerStateEnded];
        _currTouch = nil;
    }
}

- (void)makeTouche:(UITouch *)touch stateDidChange:(UIGestureRecognizerState)state {
    if (self.didChange) {
        self.didChange([touch locationInView:self.view], state);
    }
}

- (void)reset {
    [super reset];
    if (_currTouch) {
        [self makeTouche:_currTouch stateDidChange:UIGestureRecognizerStateEnded];
        _currTouch = nil;
    }
}

@end

@interface BODisplayTouchPoint () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) BODisplayTouchGesRG *pan;

@property (nonatomic, strong) UIView *touchIndexView;

@end

@implementation BODisplayTouchPoint

- (instancetype)init
{
    self = [super init];
    if (self) {
//        self.pan = [BODisplayTouchGesRG new];
    }
    return self;
}

- (BODisplayTouchGesRG *)pan {
    if (!_pan) {
        _pan = [BODisplayTouchGesRG new];
    }
    return _pan;
}

#define sf_bind_key @"BODisplayTouchPoint-bind-key"

+ (BODisplayTouchPoint *)addToView:(UIView *)view
{
    if (!view) {
        return nil;
    }
    
    BODisplayTouchPoint *dt = objc_getAssociatedObject(view, sf_bind_key);
    if (!dt) {
        dt = [BODisplayTouchPoint new];
        [view addGestureRecognizer:dt.pan];
    }
    objc_setAssociatedObject(view, sf_bind_key, dt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    __weak typeof(dt) wdt = dt;
    dt.pan.didChange = ^(CGPoint pt, UIGestureRecognizerState state) {
        [wdt onPan:pt state:state];
    };
    
    return dt;
}

+ (void)removeWithView:(UIView *)view
{
    if (!view) {
        return;
    }
    
    BODisplayTouchPoint *dt = objc_getAssociatedObject(view, sf_bind_key);
    if (dt) {
        [view removeGestureRecognizer:dt.pan];
        objc_setAssociatedObject(view, sf_bind_key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)onPan:(CGPoint)pt state:(UIGestureRecognizerState)state
{
    
    switch (state) {
        case UIGestureRecognizerStateBegan:
        {
            [self.pan.view addSubview:self.touchIndexView];
            self.touchIndexView.center = pt;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.touchIndexView.center = pt;
        }
            break;
        default:
        {
            [self.touchIndexView removeFromSuperview];
        }
            break;
    }
    
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (UIView *)touchIndexView
{
    if (!_touchIndexView) {
        _touchIndexView = [UIView new];
        _touchIndexView.userInteractionEnabled = NO;
        _touchIndexView.bounds = CGRectMake(0, 0, 48, 48);
        _touchIndexView.layer.cornerRadius = 24;
        _touchIndexView.layer.backgroundColor = [UIColor colorWithRed:0.16 green:1 blue:0 alpha:0.7].CGColor;
    }
    return _touchIndexView;
}

@end
