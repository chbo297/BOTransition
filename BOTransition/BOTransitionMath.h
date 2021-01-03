//
//  BOTransitionMath.h
//  BOTransition
//
//  Created by bo on 2020/12/6.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXTERN void bo_addCATransactionCompletionTask(NSString *key, void(^task)(void));

FOUNDATION_EXTERN CGRect botransition_rectWithAspectFitForBounding(CGRect bounding, CGSize size);
FOUNDATION_EXTERN CGRect botransition_rectWithAspectFillForBounding(CGRect bounding, CGSize size);

FOUNDATION_EXTERN CGFloat botransition_clip(CGFloat min, CGFloat max, CGFloat val);
FOUNDATION_EXTERN CGFloat botransition_lerp(CGFloat v0, CGFloat v1, CGFloat t);

FOUNDATION_EXTERN CGAffineTransform botransition_getTransform(CGRect from, CGRect to);

