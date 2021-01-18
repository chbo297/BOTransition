//
//  BODisplayTouchPoint.h
//  TEUIUse
//
//  Created by bo on 2019/7/11.
//  Copyright © 2019 bo. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface BODisplayTouchPoint : NSObject

+ (BODisplayTouchPoint *)addToView:(UIView *)view;
+ (void)removeWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
