//
//  BOTransitionEffectFadeImp.h
//  BOTransition
//
//  Created by bo on 2020/12/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*
 {
 @"style": @"Fade",
 */
@interface BOTransitionEffectFadeImp : NSObject <BOTransitionEffectControl>

/*
 alphaCalPow: @(CGFloat)
 */
@property (nonatomic, strong, nullable) NSDictionary *configInfo;

@end

NS_ASSUME_NONNULL_END
