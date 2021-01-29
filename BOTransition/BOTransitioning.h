//
//  BOTransitioning.h
//  BOTransition
//
//  Created by bo on 2020/7/27.
//  Copyright © 2020 bo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BOTransitionConfig.h"
#import "BOTransitionPanGesture.h"
#import "BOTransitionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN const NSNotificationName BOTransitionWillAndMustCompletion;

@interface BOTransitioning : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

@property (nonatomic, readonly) BOTransitionType transitionType;

+ (instancetype)transitioningWithType:(BOTransitionType)transitionType;

- (instancetype)initWithTransitionType:(BOTransitionType)transitionType NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

//present/push动作发生之前前已经在展示的基准VC
@property (nonatomic, readonly) UIViewController *baseVC;
//present/push动作的入场VC以及 dismiss/pop动作的离场VC
@property (nonatomic, readonly) UIViewController *moveVC;

@property (nonatomic, readonly) UIView *commonBg;
@property (nonatomic, readonly) UIView *checkAndInitCommonBg;

@property (nonatomic, weak) BOTransitionConfig *moveVCConfig;

@property (nonatomic, readonly, nonnull) BOTransitionPanGesture *transitionGes;

@property (nonatomic, readonly) BOOL triggerInteractiveTransitioning;

@property (nonatomic, readonly) id<UIViewControllerContextTransitioning> transitionContext;

//外部控制 每个周期前必须被设置为正确的类型
@property (nonatomic, assign) BOTransitionAct transitionAct;

@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, weak) UITabBarController *tabBarController;

/*
 return:
 1 保留ges
 2 保留otherges
 0 没有判断出结果
 */
+ (NSInteger)checkWithVC:(UIViewController *)vc
          transitionType:(BOTransitionType)transitionType
                makeFail:(BOOL)makeFail
                 baseGes:(UIGestureRecognizer *)ges
      otherTransitionGes:(UIGestureRecognizer *)otherGes;

@end

@interface BOTransitionElement : NSObject

+ (instancetype)elementWithType:(BOTransitionElementType)type;

@property (nonatomic, assign) BOTransitionElementType elementType;

@property (nonatomic, strong, nullable) UIView *transitionView;


@property (nonatomic, weak) UIView *fromView;
@property (nonatomic, weak) UIView *toView;
@property (nonatomic, strong) NSValue *toFrameCoordinateInVC;

/*
 YES：
 在转场过程中，自动hidden fromView和toView
 在结束后自动还原
 
 NO：
 不修改fromView和toView的hidden状态
 
 default:YES
 */
@property (nonatomic, assign) BOOL fromViewAutoHidden;
@property (nonatomic, assign) BOOL toViewAutoHidden;

/*
 //内部不用，但提供一个可挂载信息的属性，外部有需要时可以用
 @{@"type": @"movedBoard"}
 */
@property (nonatomic, strong, nullable) NSMutableDictionary *userInfo;

- (void)addToStep:(BOTransitionStep)step
            block:(void (^)(BOTransitioning *transitioning,
                            BOTransitionStep step,
                            BOTransitionElement *transitionElement,
                            BOTransitionInfo transitionInfo,
                            NSDictionary * _Nullable subInfo))block;

/*
 ani: @(YES/NO)
 */
- (void)execTransitioning:(BOTransitioning *)transitioning
                     step:(BOTransitionStep)step
           transitionInfo:(BOTransitionInfo)transitionInfo
                  subInfo:(nullable NSDictionary *)subInfo;


//at least prepare for step PrepareAndInstallElements
//是否进行transform转变
@property (nonatomic, assign) BOOL frameAllow;
//0-1
@property (nonatomic, assign) CGFloat frameInteractiveLimit;
@property (nonatomic, assign) BOOL frameShouldPin;
//手势初始位置时相对于transformRectFrom的anchor，例如在transformRectFrom中心点时是(0,0),在transformRectFrom最右上角时是(0.5,0.5)，左下角是(-0.5,-0.5)
@property (nonatomic, assign) CGPoint framePinAnchor;
@property (nonatomic, assign) CGRect frameOrigin;
@property (nonatomic, assign) CGRect frameFrom;
@property (nonatomic, assign) CGRect frameTo;
@property (nonatomic, assign) CGFloat frameCalPow;
@property (nonatomic, assign) BOOL frameAnimationWithTransform;
@property (nonatomic, assign) UIRectEdge frameBarrierInContainer;
@property (nonatomic, strong) NSValue *frameLastBeforeAni;


//是否进行alpha转变
@property (nonatomic, assign) BOOL alphaAllow;
//0-1
@property (nonatomic, assign) CGFloat alphaInteractiveLimit;
//暂只支持CalPow方式，若需要更丰富的曲线函数后续再扩展吧
@property (nonatomic, assign) CGFloat alphaCalPow;
@property (nonatomic, assign) CGFloat alphaFrom;
@property (nonatomic, assign) CGFloat alphaTo;
@property (nonatomic, assign) CGFloat alphaOrigin;

@property (nonatomic, strong) NSNumber *alphaLastBeforeAni;

- (CGFloat)interruptAnimation:(BOTransitionInfo)transitionInfo;
/*
 "aniPercent":
 */
- (void)interruptAnimationAndResetPorperty:(BOTransitioning *)transitioning
                            transitionInfo:(BOTransitionInfo)transitionInfo
                                   subInfo:(nullable NSDictionary *)subInfo;

@end

NS_ASSUME_NONNULL_END
