//
//  BOTransitionNCProxy.h
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class BOTransitioning;
@protocol BOTransitionEffectControl;

@interface BOTransitionNCProxy : NSProxy <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

//转场执行者
@property (nonatomic, readonly) BOTransitioning *transitioning;

/*
 navigationController的delegate，当外部需要使用UINavigationController的delegate时可在此设置
 
 但会截留以下两个方法用作转场动画，且不会向外抛（因为不希望外界用两个方法篡改内部的转场逻辑，如果以后遇到有需要再考虑是否抛出吧）
 navigationController:animationControllerForOperation:fromViewController:toViewController:
 navigationController:interactionControllerForAnimationController:
 */
@property(nullable, nonatomic, weak) id<UINavigationControllerDelegate> navigationControllerDelegate;

/*
 BOTransitionNCProxy.defaultNavigationBarHiddenAndAutoSet: NSNumber<BOOL>
 default: nil
 有值时，会在切页时自动设置NavigationBar的hidden状态
 根据目标页面的UINavigationItem.bo_navigationBarHidden的值，若bo_navigationBarHidden为nil，则将NavigationBarHidden设定为defaultNavigationBarHiddenAndAutoSet的值
 若bo_navigationBarHidden有值，则设定对应的值
 
 比如当默认全局NavigationBar隐藏时，把defaultNavigationBarHiddenAndAutoSet设置为@(YES)
 只有一些页面需要额外展示时，把对应页面的UINavigationItem.bo_navigationBarHidden设置为@(NO)
 可以实现所有没额外设置的页面默认都不展示，只有设置了@(NO)才展示navigationBar
 反正可以让全局都展示，只有对应页面不展示
 */
@property (nonatomic, strong) NSNumber *defaultNavigationBarHiddenAndAutoSet;

//内部使用
@property (nonatomic, readonly) id<BOTransitionEffectControl> transitionEffectControl;

@end

@interface UINavigationController (BOTransition)

/*
 在navigationController viewDidLoad 中调用，
 需要作为navigationController的delegate和navigationController.interactivePopGestureRecognizer的delegate使用
 外部请不要再修改navigationController.interactivePopGestureRecognizer的delegate
 
 bo_setTransProxy:YES后bo_transProxy有值
 bo_setTransProxy:NO 后bo_transProxy无值
 使用bo_transProxy的时候，bo_transProxy会成为UINavigationController的delegate，如果需要使用delegate，请不要直接更改，
 BOTransitionNCProxy会把系统回调转发到navigationControllerDelegate上。
 可以使用BOTransitionNCProxy的navigationControllerDelegate来获取原系统方法回调。
 */
- (void)bo_setTransProxy:(BOOL)use;
@property (nonatomic, readonly) BOTransitionNCProxy *bo_transProxy;

/*
 一个有completion的便利方法
 bo_transProxy开启时，该方法才能用，否则执行无效
 */
- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
                  animated:(BOOL)animated
                completion:(void (^ _Nullable)(BOOL finish, NSDictionary * _Nullable info))completion;

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
                  animated:(BOOL)animated
                  userInfo:(nullable NSDictionary *)userInfo
                completion:(void (^ _Nullable)(BOOL finish, NSDictionary * _Nullable info))completion;

@end

@interface UINavigationItem (BOTransition)

/*
 见 BOTransitionNCProxy.defaultNavigationBarHiddenAndAutoSet
 */
@property (nonatomic) NSNumber *bo_navigationBarHidden;

@end

NS_ASSUME_NONNULL_END
