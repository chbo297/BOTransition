//
//  BOTransitionNCProxy_privacy.h
//  BOTransitionDemo
//
//  Created by bo on 2023/11/16.
//

#import "BOTransitionNCProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface BOTransitionNCProxy ()

//承接转场是，内部的一些控制机制
@property (nonatomic, readonly) id<BOTransitionEffectControl> transitionEffectControl;

@end

NS_ASSUME_NONNULL_END
