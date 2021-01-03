//
//  BOTransitionProtocol.h
//  BOTransition
//
//  Created by bo on 2021/1/3.
//
#import "BOTransitionUtility.h"

#ifndef BOTransitionProtocol_h
#define BOTransitionProtocol_h

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

typedef NS_ENUM(NSUInteger, BOTransitionElementType) {
    BOTransitionElementTypeNormal = 0,
    BOTransitionElementTypeBoard,
    BOTransitionElementTypeBg,
    BOTransitionElementTypePhotoMirror,
};

@class BOTransitioning;
@class BOTransitionElement;
@class BOTransitionPanGesture;

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END

#endif /* BOTransitionProtocol_h */
