//
//  UIViewController+BOTransition.h
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BOTransitionConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (BOTransition)

@property (nonatomic, strong, nullable) BOTransitionConfig *bo_transitionConfig;

/*
 当触发了动画转场，或者交互转场的交互结束后，当生成了动画并提交开始播放后（即执行完动画代码的下一个RunLoop），会调用该方法
 如果有不得已的主线程耗时操作，可以放在此方法中，不会阻塞动画播放，动画播放结束前由于动画的播放用户感受不到UI卡顿
 */
- (void)bo_transitionWillCompletion:(BOOL)willCompletion userInfo:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
