//
//  BOTransitionEffectElementExpensionImp.h
//  BOTransition
//
//  Created by bo on 2020/11/30.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionProtocol.h"
#import "BOTransitioning.h"

NS_ASSUME_NONNULL_BEGIN
/*
 @"style": @"ElementExpension",
 @"config": @{
 @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
 //控制转场元素是否吸附手指位置
 @"pinGes": @(NO),
 //有pinGesEle时，pinGesEle控制startView是否吸附手指位置，pinGes改为控制board（VC的View）
 @"pinGesEle": @(YES),
 //是否禁止board（VC的View）的frame移动，只进行alpha变化
 @"disableBoardMove": @(YES),
 //YES时，不添加startView的转场效果，只参考startView的位置
 @"onlyBoard": @(NO),
 @"bg": @(YES),
 @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
 }
 */
// ElementExpension
@interface BOTransitionEffectElementExpensionImp : NSObject <BOTransitionEffectControl>

/*
 @"pinGes": @(YES)
 @"zoomContentMode": @(UIViewContentMode)
 */
@property (nonatomic, strong, nullable) NSDictionary *configInfo;

@end


@interface BOTransitionElement (Effect)

/*
 添加一个BOTransitionStepInstallElements阶段的任务
 该任务会根据现有的fromview和toview添加一个不同view转化的动效
 */
- (void)makeTransitionEffect:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
