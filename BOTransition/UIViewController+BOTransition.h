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

@end

NS_ASSUME_NONNULL_END
