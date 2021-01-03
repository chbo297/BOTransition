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

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BOTransitionType) {
    BOTransitionTypeNone                = 0,
    BOTransitionTypeModalPresentation   = 1,
    BOTransitionTypeNavigation          = 2,
    BOTransitionTypeTabBar              = 3
};

typedef NS_ENUM(NSUInteger, BOTransitionAct) {
    BOTransitionActNone         = 0,
    BOTransitionActMoveIn       = 1,
    BOTransitionActMoveOut      = 2,
};

typedef NS_ENUM(NSUInteger, BOTransitionStep) {
    BOTransitionStepNone = 0,
    BOTransitionStepInstallElements,
    BOTransitionStepAfterInstallElements,
    BOTransitionStepInitialAnimatableProperties,
    BOTransitionStepTransitioning,
    BOTransitionStepFinalAnimatableProperties,
    BOTransitionStepCompleted,
    BOTransitionStepCancelled,
    
    BOTransitionStepInteractiveEnd,
};

typedef struct BOTransitionInfo {
    CGFloat percentComplete;
    BOOL interactive;
    CGPoint panBeganLoc;
    CGPoint panCurrLoc;
} BOTransitionInfo;

@class BOTransitioning;
@class BOTransitionElement;

@protocol BOTransitionEffectControl <NSObject>

@optional

@property (nonatomic, readwrite, nullable) NSDictionary *configInfo;

- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements;

/*
 不实现的默认情况下，竖滑整个container高代表全程，横滑整个container的宽代表全程
 */
- (CGFloat)bo_transitioningDistanceCoefficient:(UISwipeGestureRecognizerDirection)direction;

@end

@protocol BOTransitionConfigDelegate <BOTransitionEffectControl>

@optional

//当该手势触发时，是否需要以该手势为交互，用transitionType展示某个VC
- (UIViewController *)bo_trans_moveInVCWithGes:(BOTransitionPanGesture *)gesture
                                transitionType:(BOTransitionType)transitionType
                                       subInfo:(nullable NSDictionary *)subInfo;

/*
 当该手势触发时，是否需要退场该viewController
 nil: 不触发退场，但不排除该手势继续滑动，一会儿当触发了某个方向时会继续尝试触发
 YES: 触发交互式退场
 NO: 不可以开始并且取消本次手势响应
 */
- (NSNumber *)bo_trans_shouldMoveOutVC:(UIViewController *)viewController
                               gesture:(BOTransitionPanGesture *)gesture
                        transitionType:(BOTransitionType)transitionType
                               subInfo:(nullable NSDictionary *)subInfo;

/*
 成功触发交互式退场后，如
 1.没有实现bo_trans_shouldMoveOutVC方法，合法手势触发了交互式退场
 2.实现了bo_trans_shouldMoveOutVC方法，合法手势触发了交互式退场获得了bo_trans_shouldMoveOutVC返回YES
 
 如果实现了bo_trans_actMoveOutVC并且返回YES，代表接管本次pop事件，请在bo_trans_actMoveOutVC方法中保证最终调用Pop相关操作
 返回NO或没实现，控件会自己调用navigationController popViewControllerAnimated:YES
 */
- (BOOL)bo_trans_actMoveOutVC:(UIViewController *)viewController
                      gesture:(BOTransitionPanGesture *)gesture
               transitionType:(BOTransitionType)transitionType
                      subInfo:(nullable NSDictionary *)subInfo;

@end


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

@end

typedef NS_ENUM(NSUInteger, BOTransitionElementType) {
    BOTransitionElementTypeNormal = 0,
    BOTransitionElementTypeBoard,
    BOTransitionElementTypeBg,
    BOTransitionElementTypePhotoMirror,
};

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
@property (nonatomic, assign) BOOL frameAnimationWithTransform;
@property (nonatomic, assign) BOOL frameBarrierInContainer;
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
