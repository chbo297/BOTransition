# BOTransition
iOS Transitioning Effect

[![Version](https://img.shields.io/cocoapods/v/BOTransition.svg?style=flat)](http://cocoapods.org/pods/BOTransition)
![License](https://img.shields.io/cocoapods/l/BOTransition.svg?style=flat)
![Platform](https://img.shields.io/cocoapods/p/BOTransition.svg?style=flat)

![交互转场](https://github.com/chbo297/BOTransition/blob/main/demov.gif)

## CocoaPods
pod 'BOTransition'

https://cocoapods.org/pods/BOTransition

## In Objective-C

```

#import <BOTransition/BOTransition.h>

UIViewController *viewController = [UIViewController new];
viewController.bo_transitionConfig = [BOTransitionConfig configWithEffect:BOTransitionEffectMovingRight];
[self presentViewController:viewController animated:YES completion:nil];

```

