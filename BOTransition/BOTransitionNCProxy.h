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
@interface BOTransitionNCProxy : NSProxy <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

/*
 在navigationController viewDidLoad 中调用，
 需要作为navigationController的delegate和navigationController.interactivePopGestureRecognizer的delegate使用
 外部请不要再修改navigationController.interactivePopGestureRecognizer的delegate
 如果需要使用navigationController的delegate，使用该类的navigationControllerDelegate即可
 
 eg.
 UINavigationController:
 
 - (void)viewDidLoad {
 [super viewDidLoad];
 
 self.ncProxy = [[BOTransitionNCProxy alloc] initWithNC:self];
 }
 */
+ (instancetype)transitionProxyWithNC:(UINavigationController *)navigationController;

- (instancetype)initWithNC:(UINavigationController *)navigationController;

/*
 navigationController的delegate，当外部需要使用UINavigationController的delegate时可在此设置
 
 但会截留以下两个方法用作转场动画，且不会向外抛（因为不希望外界用两个方法篡改内部的转场逻辑，如果以后遇到有需要再考虑是否抛出吧）
 navigationController:animationControllerForOperation:fromViewController:toViewController:
 navigationController:interactionControllerForAnimationController:
 */
@property(nullable, nonatomic, weak) id<UINavigationControllerDelegate> navigationControllerDelegate;

@end

@interface UINavigationController (BOTransition)

@property (nonatomic, readonly) BOTransitionNCProxy *bo_transProxy;
- (void)bo_setTransProxy:(BOOL)use;

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
                  animated:(BOOL)animated
                completion:(void (^ _Nullable)(BOOL finish, NSDictionary * _Nullable info))completion;

@end

NS_ASSUME_NONNULL_END
