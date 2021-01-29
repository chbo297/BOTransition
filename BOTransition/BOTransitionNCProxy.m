//
//  BOTransitionNCProxy.m
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionNCProxy.h"
#import <objc/runtime.h>
#import "UIViewController+BOTransition.h"
#import "BOTransitioning.h"

/*
 处理系统的pop手势
 */
@interface BOTransitionNCPopGestureHandler : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation BOTransitionNCPopGestureHandler {
    id _originDelegate;
}

- (void)setNavigationController:(UINavigationController *)navigationController {
    if (_navigationController) {
        _navigationController.interactivePopGestureRecognizer.delegate = _originDelegate;
        _originDelegate = nil;
        _navigationController = nil;
    }
    
    if (navigationController) {
        _navigationController = navigationController;
        _originDelegate = _navigationController.interactivePopGestureRecognizer.delegate;
        _navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UINavigationController *nc = self.navigationController;
    if (!nc) {
        return NO;
    }
    if (gestureRecognizer == nc.interactivePopGestureRecognizer) {
        if (nc.viewControllers.count <= 1) {
            //没有可pop的VC，不响应手势
            return NO;
        }
        
        UIViewController *topvc = nc.viewControllers.lastObject;
        BOTransitionConfig *transitconfig = topvc.bo_transitionConfig;
        if (transitconfig && !transitconfig.moveOutUseOrigin) {
            //顶部VC配置了不支持interactivePopGestureRecognizer
            return NO;
        } else {
            NSNumber *shouldMoveOut = @(YES);
            id<BOTransitionConfigDelegate> configdelegate = transitconfig.configDelegate;
            if (!configdelegate) {
                configdelegate = (id)topvc;
            }
            if (configdelegate
                && [configdelegate respondsToSelector:@selector(bo_trans_shouldMoveOutVC:gesture:transitionType:subInfo:)]) {
                NSNumber *control = [configdelegate bo_trans_shouldMoveOutVC:topvc
                                                                     gesture:gestureRecognizer
                                                              transitionType:BOTransitionTypeNavigation
                                                                     subInfo:@{@"nc": nc}];
                if (nil != control) {
                    shouldMoveOut = control;
                }
            }
            
            return shouldMoveOut.boolValue;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer
        && otherGestureRecognizer != gestureRecognizer) {
        
        if ([BOTransitionPanGesture isTransitonGes:otherGestureRecognizer]) {
            NSInteger strategy =\
            [BOTransitioning checkWithVC:self.navigationController.viewControllers.lastObject
                          transitionType:BOTransitionTypeNavigation
                                makeFail:YES
                                 baseGes:gestureRecognizer
                      otherTransitionGes:otherGestureRecognizer];
            
            if (2 == strategy) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer
        && otherGestureRecognizer != gestureRecognizer) {
        
        if ([BOTransitionPanGesture isTransitonGes:otherGestureRecognizer]) {
            NSInteger strategy =\
            [BOTransitioning checkWithVC:self.navigationController.viewControllers.lastObject
                          transitionType:BOTransitionTypeNavigation
                                makeFail:YES
                                 baseGes:gestureRecognizer
                      otherTransitionGes:otherGestureRecognizer];
            
            if (1 == strategy) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

@end


/*
 处理转场代理
 */
@interface BOTransitionNCHandler : NSObject <UINavigationControllerDelegate>

@property (nonatomic, weak) BOTransitionNCProxy *ncProxy;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, strong) BOTransitioning *transitioning;

@property (nonatomic, copy) void(^ncDidShowVCCallback)(UINavigationController *nc, UIViewController *vc, BOOL animated);

@end

@implementation BOTransitionNCHandler

- (BOTransitioning *)transitioning {
    if (!_transitioning) {
        _transitioning = [BOTransitioning transitioningWithType:BOTransitionTypeNavigation];
    }
    return _transitioning;
}

- (void)setNavigationController:(UINavigationController *)navigationController {
    
    _navigationController = navigationController;
    
    self.transitioning.navigationController = _navigationController;
    
    UIGestureRecognizer *transitionGes = self.transitioning.transitionGes;
    if (![_navigationController.view.gestureRecognizers containsObject:transitionGes]) {
        [_navigationController.view addGestureRecognizer:transitionGes];
    }
}

#pragma mark - UINavigationControllerDelegate

- (nullable id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                  interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if (animationController != self.transitioning) {
        return nil;
    }
    
    if (self.transitioning.triggerInteractiveTransitioning) {
        return self.transitioning;
    }
    
    return nil;
}

- (nullable id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                           animationControllerForOperation:(UINavigationControllerOperation)operation
                                                        fromViewController:(UIViewController *)fromVC
                                                          toViewController:(UIViewController *)toVC {
    id<UIViewControllerAnimatedTransitioning> transitioning;
    
    switch (operation) {
        case UINavigationControllerOperationNone: {
            transitioning = nil;
        }
            break;
        case UINavigationControllerOperationPush: {
            BOTransitionConfig *config = toVC.bo_transitionConfig;
            if (!config ||
                config.moveInUseOrigin) {
                transitioning = nil;
            } else {
                self.transitioning.transitionAct = BOTransitionActMoveIn;
                transitioning = self.transitioning;
            }
        }
            break;
        case UINavigationControllerOperationPop: {
            BOTransitionConfig *config = fromVC.bo_transitionConfig;
            if (!config ||
                config.moveOutUseOrigin) {
                transitioning = nil;
            } else {
                self.transitioning.transitionAct = BOTransitionActMoveOut;
                transitioning = self.transitioning;
            }
        }
            break;
        default:
            break;
    }
    
    return transitioning;
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (self.ncDidShowVCCallback) {
        self.ncDidShowVCCallback(navigationController, viewController, animated);
    }
    
    if (self.ncProxy.navigationControllerDelegate
        && [self.ncProxy.navigationControllerDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.ncProxy.navigationControllerDelegate navigationController:navigationController
                                                  didShowViewController:viewController
                                                               animated:animated];
    }
}

@end


/*
 分发事件
 */
@interface BOTransitionNCProxy ()

@property (nonatomic, strong) BOTransitionNCHandler *transitionNCHandler;
@property (nonatomic, strong) BOTransitionNCPopGestureHandler *popGestureHandler;

@end

@implementation BOTransitionNCProxy

- (instancetype)initWithNC:(UINavigationController *)navigationController {
    
    _transitionNCHandler = [BOTransitionNCHandler new];
    _transitionNCHandler.ncProxy = self;
    _transitionNCHandler.navigationController = navigationController;
    
    navigationController.delegate = self;
    
    _popGestureHandler = [BOTransitionNCPopGestureHandler new];
    _popGestureHandler.navigationController = navigationController;
    
    return self;
}

- (BOTransitioning *)transitioning {
    return self.transitionNCHandler.transitioning;
}

/*
 分发消息
 */
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([_transitionNCHandler respondsToSelector:aSelector]) {
        return _transitionNCHandler;
    } else if (_navigationControllerDelegate &&
               [_navigationControllerDelegate respondsToSelector:aSelector])  {
        return _navigationControllerDelegate;
    } else {
        return nil;
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([_transitionNCHandler respondsToSelector:aSelector]) {
        return YES;
    } else if (_navigationControllerDelegate &&
               [_navigationControllerDelegate respondsToSelector:aSelector])  {
        return YES;
    } else if (aSelector == @selector(transitionNCHandler)) {
        return YES;
    } else {
        return NO;
    }
}

@end

@interface UINavigationController (BOTransition_inner)

- (void)bo_transitioning_setViewControllers:(NSArray<UIViewController *> *)viewControllers
                                   animated:(BOOL)animated;
- (NSArray<__kindof UIViewController *> *)bo_transitioning_popToViewController:(UIViewController *)viewController
                                                                      animated:(BOOL)animated;

@end

@implementation UINavigationController (BOTransition)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /*
         添加一个方法bo_transitioning_setViewControllers复制
         setViewControllers
         的实现
         */
        [BOTransitionUtility copyOriginMeth:@selector(setViewControllers:animated:)
                                     newSel:@selector(bo_transitioning_setViewControllers:animated:)
                                      class:self];
        [BOTransitionUtility copyOriginMeth:@selector(popToViewController:animated:)
                                     newSel:@selector(bo_transitioning_popToViewController:animated:)
                                      class:self];
    });
}

- (BOTransitionNCProxy *)bo_transProxy {
    return objc_getAssociatedObject(self, @selector(bo_transProxy));
}

- (void)bo_setTransProxy:(BOOL)use {
    BOTransitionNCProxy *ncproxy = objc_getAssociatedObject(self, @selector(bo_transProxy));
    if (use) {
        if (ncproxy) {
            //已经有了，什么也不做
            return;
        } else {
            //还没有，新建并保存
            ncproxy = [[BOTransitionNCProxy alloc] initWithNC:self];
            objc_setAssociatedObject(self, @selector(bo_transProxy),
                                     ncproxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    } else {
        if (ncproxy) {
            //清空
            if (ncproxy == self.delegate) {
                self.delegate = nil;
            }
            objc_setAssociatedObject(self, @selector(bo_transProxy),
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finish, NSDictionary *info))completion {
    BOTransitionNCProxy *ncproxy = self.bo_transProxy;
    if (!ncproxy) {
        return;
    }
    
    if ((viewControllers.count <= 0
         && animated)
        || (self.viewControllers.lastObject.transitionCoordinator
            || viewControllers.lastObject.transitionCoordinator)) {
        //容错修正
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    
    NSArray<UIViewController *> *originvcar = self.viewControllers.copy;
    BOOL ispop = NO;
    if (viewControllers.count > 0
        && viewControllers.count < originvcar.count) {
        __block BOOL isequal = YES;
        [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (originvcar[idx] != obj) {
                isequal = NO;
                *stop = YES;
            }
        }];
        
        ispop = isequal;
    }
    if (ispop) {
        //pop是用setViewControllers后，self.viewControllers状态有问题，使用popToViewController没问题
        [self bo_transitioning_popToViewController:viewControllers.lastObject animated:animated];
    } else {
        [self bo_transitioning_setViewControllers:viewControllers animated:animated];
    }
    
    if (completion) {
        //如果有转场动画，设置结束回调
        id <UIViewControllerTransitionCoordinator> tcdt =\
        viewControllers.lastObject.transitionCoordinator;
        if (tcdt) {
            [tcdt animateAlongsideTransition:nil
                                  completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                completion(!context.cancelled, nil);
            }];
        } else {
            //不需要等待ncDidShowVCCallback再结束了，直接当结束就好了,系统是兼容没转场的时候连续调用的
            //            if (viewControllers.lastObject != originvcar.lastObject) {
            //                __weak typeof(ncproxy) wkncp = ncproxy;
            //                __weak typeof(self) ws = self;
            //                ncproxy.transitionNCHandler.ncDidShowVCCallback = ^(UINavigationController *nc, UIViewController *vc, BOOL animated) {
            //                    if (ws == nc) {
            //                        void (^savcompletion)(BOOL finish, NSDictionary *info) = completion;
            //                        wkncp.transitionNCHandler.ncDidShowVCCallback = nil;
            //                        savcompletion(YES, nil);
            //                    }
            //                };
            //            } else {
            completion(YES, nil);
            //            }
            
        }
    }
    
}

@end
