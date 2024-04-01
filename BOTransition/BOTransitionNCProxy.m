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
        
        //已经在自定义转场中，不再触发系统的
        if (nc.bo_transProxy.transitioning.triggerInteractiveTransitioning) {
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
        
        //有对应策略时执行策略
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
        
        //没有其它策略时，系统的interactivePopGestureRecognizer需要把其它手势取消掉
        return YES;
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
@interface BOTransitionNCHandler : NSObject <UINavigationControllerDelegate, BOTransitionEffectControl>

@property (nonatomic, weak) BOTransitionNCProxy *ncProxy;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, strong) BOTransitioning *transitioning;

//用来抓取viewDidLayoutSubviews方法
@property (nonatomic, copy) void(^viewDidLayoutSubviewsCallback)(UINavigationController *nc,
                                                                 BOOL layoutYESOrCancelNO);

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
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [self checkEnvironmentForVC:viewController];
    
    if (self.ncProxy.navigationControllerDelegate
        && [self.ncProxy.navigationControllerDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.ncProxy.navigationControllerDelegate navigationController:navigationController
                                                 willShowViewController:viewController
                                                               animated:animated];
    }
}

/*
 vc即将展示，配置相关环境  如该vc是否需要控制navigationBar的展示状态、屏幕的旋转等
 */
- (void)checkEnvironmentForVC:(UIViewController *)vc {
    if (!vc) {
        return;
    }
    
    //navigationBar
    NSNumber *autoSetnbh = self.navigationController.bo_transProxy.defaultNavigationBarHiddenAndAutoSet;
    if (nil != autoSetnbh) {
        //更新navigationBar状态
        BOOL shouldhidden = autoSetnbh.boolValue;
        NSNumber *vcnbh = vc.navigationItem.bo_navigationBarHidden;
        if (nil != vcnbh) {
            shouldhidden = vcnbh.boolValue;
        }
        if (shouldhidden != self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:shouldhidden animated:YES];
        }
    }
}

#pragma mark - BOTransitionEffectControl
- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements {
    if (BOTransitionStepInstallElements != step) {
        return;
    }
    
    /*
     若需要管理NavigationBar的Hidden，则在开始、结束、取消都check状态
     目前有个系统bug，在自定义转场取消时，NavigationBar内容没恢复
     */
    if (nil != self.navigationController.bo_transProxy.defaultNavigationBarHiddenAndAutoSet) {
        //添加更新navigationBar状态的transition effect element
        BOTransitionElement *ele = [BOTransitionElement new];
        __weak typeof(self) ws = self;
        [ele addToStep:BOTransitionStepWillBegin | BOTransitionStepWillFinish | BOTransitionStepWillCancel
                 block:^(BOTransitioning * _Nonnull transitioning, BOTransitionStep step, BOTransitionElement * _Nonnull transitionElement, BOTransitionInfo transitionInfo, NSDictionary * _Nullable subInfo) {
            switch (step) {
                case BOTransitionStepWillBegin:
                case BOTransitionStepWillFinish:
                    //即将开始和即将结束时确保更新到了目标vc的状态
                    [ws checkEnvironmentForVC:transitioning.desVC];
                    break;
                case BOTransitionStepWillCancel:
                    [ws checkEnvironmentForVC:transitioning.startVC];
                    break;
                default:
                    break;
            }
        }];
        [elements addObject:ele];
    }
    
//    if (!transitioning.navigationController.navigationBarHidden) {
//        //取消时恢复bar的内容
//        UINavigationItem *startitem = startvc.navigationItem;
//        UINavigationBar *nbar = transitioning.navigationController.navigationBar;
//        if (startitem
//            && nbar) {
//            if (![nbar.items containsObject:startitem]) {
//                //有问题，bar的内容没有恢复，系统有bug。这里如果手动push一下原内容理论上可以修复，但系统做了个exception不让外部执行，后续再想办法吧
//            }
//
//        }
//    }
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
    
    _popGestureHandler = [BOTransitionNCPopGestureHandler new];
    _popGestureHandler.navigationController = navigationController;
    
    return self;
}

- (BOTransitioning *)transitioning {
    return self.transitionNCHandler.transitioning;
}

- (id<BOTransitionEffectControl>)transitionEffectControl {
    return self.transitionNCHandler;
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
    //先从自己的方法列表中找找
    int i = 0;
    unsigned int mcount = 0;
    Method *mlist = class_copyMethodList(self.class, &mcount);
    for (i = 0; i < mcount; i++) {
        SEL selval = method_getName(mlist[i]);
        if (aSelector == selval) {
            return YES;
        }
    }
    
    if (mlist) {
        free(mlist);
    }
    
    //自己没实现，再问下transitionNCHandler和navigationControllerDelegate
    if ([_transitionNCHandler respondsToSelector:aSelector]) {
        return YES;
    } else if (_navigationControllerDelegate &&
               [_navigationControllerDelegate respondsToSelector:aSelector])  {
        return YES;
    } else {
        //都不响应则返回NO
        return NO;
    }
}

@end

@interface UINavigationController (BOTransition_inner)

- (void)bo_trans_setViewControllers:(NSArray<UIViewController *> *)viewControllers
                           animated:(BOOL)animated;
- (NSArray<__kindof UIViewController *> *)bo_trans_popToViewController:(UIViewController *)viewController
                                                              animated:(BOOL)animated;
- (void)bo_trans_pushViewController:(UIViewController *)viewController
                           animated:(BOOL)animated;

@end

@implementation UINavigationController (BOTransition)

+ (void)load {
    /*
     添加一个方法bo_trans_setViewControllers复制
     setViewControllers
     的实现
     */
    [BOTransitionUtility copyOriginMeth:@selector(setViewControllers:animated:)
                                 newSel:@selector(bo_trans_setViewControllers:animated:)
                                  class:self];
    [BOTransitionUtility copyOriginMeth:@selector(popToViewController:animated:)
                                 newSel:@selector(bo_trans_popToViewController:animated:)
                                  class:self];
    [BOTransitionUtility copyOriginMeth:@selector(pushViewController:animated:)
                                 newSel:@selector(bo_trans_pushViewController:animated:)
                                  class:self];
    [BOTransitionUtility swizzleMethodTargetCls:self
                                    originalSel:@selector(viewDidLayoutSubviews)
                                         srcCls:self
                                         srcSel:@selector(bo_trans_viewDidLayoutSubviews)];
}

- (void)bo_trans_viewDidLayoutSubviews {
    [self bo_trans_viewDidLayoutSubviews];
    
    //通知transitioning该时机
    [self.bo_transProxy.transitioning ncViewDidLayoutSubviews:self];
    
    void (^vdlsc)(UINavigationController *, BOOL) =\
    self.bo_transProxy.transitionNCHandler.viewDidLayoutSubviewsCallback;
    if (vdlsc) {
        vdlsc(self, YES);
    }
}

- (BOTransitionNCProxy *)bo_transProxy {
    return objc_getAssociatedObject(self, @selector(bo_transProxy));
}

- (void)bo_setTransProxy:(BOOL)use {
    BOTransitionNCProxy *ncproxy = objc_getAssociatedObject(self, @selector(bo_transProxy));
    if (use) {
        if (!ncproxy) {
            //还没有，新建并保存
            ncproxy = [[BOTransitionNCProxy alloc] initWithNC:self];
            objc_setAssociatedObject(self, @selector(bo_transProxy),
                                     ncproxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        //delegate配置
        if (ncproxy != self.delegate) {
            self.delegate = ncproxy;
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
                completion:(void (^ _Nullable)(BOOL finish,
                                               NSDictionary * _Nullable info))completion {
    [self setViewControllers:viewControllers
                    animated:animated
                    userInfo:nil
                  completion:completion];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
                  animated:(BOOL)animated
                  userInfo:(NSDictionary *)userInfo
                completion:(void (^ _Nullable)(BOOL finish,
                                               NSDictionary * _Nullable info))completion {
    BOTransitionNCHandler *ncHandler = self.bo_transProxy.transitionNCHandler;
    if (!ncHandler) {
        return;
    }
    /*
     有未完成的待回调
     （上次调用setViewControllers:animated:completion:还没完成，completion还没执行）
     先把上次的取消掉
     */
    if (ncHandler.viewDidLayoutSubviewsCallback) {
        ncHandler.viewDidLayoutSubviewsCallback(self, NO);
    }
    
    NSArray<UIViewController *> *originvcar = self.viewControllers.copy;
    //0set 1push 2pop
    NSInteger pushact = 0;
    if (viewControllers.count > 0
        && originvcar.count > 0) {
        if (viewControllers.count != originvcar.count) {
            NSInteger mincount = MIN((NSInteger)viewControllers.count, (NSInteger)originvcar.count);
            if (mincount > 0) {
                BOOL isequal = YES;
                for (NSInteger idx = 0; idx < mincount; idx++) {
                    if (viewControllers[idx] != originvcar[idx]) {
                        isequal = NO;
                        break;
                    }
                }
                
                if (isequal) {
                    if (viewControllers.count > originvcar.count) {
                        if (viewControllers.count == originvcar.count + 1) {
                            pushact = 1;
                        }
                    } else {
                        pushact = 2;
                    }
                }
            }
        } else {
            UIViewController *showlast = viewControllers.lastObject;
            UIViewController *orilast = originvcar.lastObject;
            if (showlast != orilast
                && [originvcar containsObject:showlast]) {
                //判定可能是将一个vc从底部提上来，直接调setVC系统有bug会把顶部那个VC直接移除,这里介入排布一下
                NSMutableArray *muar = originvcar.mutableCopy;
                [muar removeObject:showlast];
                //先从底部移除
                [self bo_trans_setViewControllers:muar animated:NO];
            }
        }
        
    }
    
    switch (pushact) {
        case 1: {
            [self bo_trans_pushViewController:viewControllers.lastObject animated:animated];
        }
            break;
        case 2: {
            //pop是用setViewControllers后，self.viewControllers状态有问题，使用popToViewController没问题
            [self bo_trans_popToViewController:viewControllers.lastObject animated:animated];
        }
            break;
        default: {
            [self bo_trans_setViewControllers:viewControllers animated:animated];
        }
            break;
    }
    
    //如果有转场动画，设置结束回调
    id <UIViewControllerTransitionCoordinator> tcdt =\
    viewControllers.lastObject.transitionCoordinator;
    if (tcdt
        && viewControllers.lastObject != originvcar.lastObject) {
        /*
         有转场动画时，以动画结束为依据
         */
        [tcdt animateAlongsideTransition:nil
                              completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            completion(!context.cancelled, nil);
        }];
    } else {
        //set完后，栈是否变化成功
        __block BOOL setsuc = YES;
        if (viewControllers.count != self.viewControllers.count) {
            setsuc = NO;
        } else {
            [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj != self.viewControllers[idx]) {
                    setsuc = NO;
                    *stop = YES;
                }
            }];
        }
        
        //是否展示内容发生变更
        BOOL changedisplay = (originvcar.lastObject != viewControllers.lastObject);
        //如果发生了变化或者没有更新成功，就需要等待layout生效后再completion
        BOOL waitlayout = (changedisplay || !setsuc);
        
        //不一定会被调用到
        void (^viewdidlayoutcb)(BOOL finish, NSDictionary * _Nullable info) =\
        [userInfo objectForKey:@"viewDidLayoutCallBack"];
        
        if (waitlayout) {
            __weak typeof(ncHandler) wkhd = ncHandler;
            wkhd.viewDidLayoutSubviewsCallback =\
            ^(UINavigationController *nc, BOOL layoutYESOrCancelNO) {
                if (layoutYESOrCancelNO) {
                    __block BOOL setsuc2 = YES;
                    if (viewControllers.count != self.viewControllers.count) {
                        setsuc2 = NO;
                    } else {
                        [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if (obj != nc.viewControllers[idx]) {
                                setsuc2 = NO;
                                *stop = YES;
                            }
                        }];
                    }
                    if (setsuc2) {
                        wkhd.viewDidLayoutSubviewsCallback = nil;
                        
                        if (viewControllers.count > 0) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:BOTransitionVCViewDidMoveToContainer
                                                                                object:nc
                                                                              userInfo:@{
                                                                                  @"vc": viewControllers.lastObject
                                                                              }];
                        }
                        
                        if (viewdidlayoutcb) {
                            viewdidlayoutcb(YES, userInfo);
                        }
                        
                        /*
                         layoutsubviews时，本次转场似乎还没完全结束，此时在completion中调用push/pop在一些时机下有可能失败
                         防止外部业务在completion调用push/pop失败，这里放到下一个runloop确保转场结束后再调用completion
                         */
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            completion(YES, userInfo);
                        }];
                    }
                } else {
                    wkhd.viewDidLayoutSubviewsCallback = nil;
                    completion(NO, userInfo);
                }
            };
        } else {
            if (viewdidlayoutcb) {
                viewdidlayoutcb(YES, userInfo);
            }
            
            completion(YES, userInfo);
        }
    }
}

@end

@implementation UINavigationItem (BOTransition)

- (NSNumber *)bo_navigationBarHidden {
    return objc_getAssociatedObject(self, @selector(bo_navigationBarHidden));
}

- (void)setBo_navigationBarHidden:(NSNumber *)bo_navigationBarHidden {
    objc_setAssociatedObject(self,
                             @selector(bo_navigationBarHidden),
                             bo_navigationBarHidden,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
