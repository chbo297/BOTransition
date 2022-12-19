//
//  BOTransitionEffectMovingImp.h
//  BOTransition
//
//  Created by bo on 2020/12/7.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionProtocol.h"

NS_ASSUME_NONNULL_BEGIN
/*
 @"style": @"Moving",
 @"config": @{
 //UIRectEdgeNone时弹出默认right
 @"direction": @(UIRectEdgeRight),
 //mouvOut时的方向根据ges自适应,default NO
 @"moveOutAdaptionGes": @(YES/NO),
 }
 */
// Moving
@interface BOTransitionEffectMovingImp : NSObject <BOTransitionEffectControl>

/*
 表示页面从哪个方向移入或向哪个方向移出
 @"direction": @(UIRectEdge),
 @"bg": @(YES/NO)
 */
@property (nonatomic, strong, nullable) NSDictionary *configInfo;

+ (void)installEffect:(BOTransitioning *)transitioning
             elements:(NSMutableArray<BOTransitionElement *> *)elements
               config:(nullable NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
