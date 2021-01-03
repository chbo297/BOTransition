//
//  BOTransitionEffectElementExpensionImp.h
//  BOTransition
//
//  Created by bo on 2020/11/30.
//  Copyright © 2020 bo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BOTransition.h"

NS_ASSUME_NONNULL_BEGIN
/*
 @"style": @"ElementExpension",
 @"config": @{
         @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
         @"pinGes": @(NO),
 //YES时，不添加startView的转场效果，只参考startView的位置
 @"onlyBoard": @(NO),
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

NS_ASSUME_NONNULL_END
