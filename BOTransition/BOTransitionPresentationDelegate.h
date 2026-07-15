//
//  BOTransitionPresentationDelegate.h
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BOTransitioning;

@interface BOTransitionPresentationDelegate : NSObject <UIViewControllerTransitioningDelegate>

/*
 预制的transitioning
 */
@property (nonatomic, weak, nullable) BOTransitioning *preTransition;

@property (nonatomic, readonly, nullable) BOTransitioning *currTransitioning;

@end

NS_ASSUME_NONNULL_END
