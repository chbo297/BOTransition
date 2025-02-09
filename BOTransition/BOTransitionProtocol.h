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
    BOTransitionStepNone                            = 0 << 0,
    BOTransitionStepInstallElements                 = 1 << 0,
    BOTransitionStepAfterInstallElements            = 1 << 1,
    BOTransitionStepInitialAnimatableProperties     = 1 << 2,
    
    BOTransitionStepWillBegin                       = 1 << 3,
    BOTransitionStepTransitioning                   = 1 << 4,
    BOTransitionStepFinalAnimatableProperties       = 1 << 5,
    
    BOTransitionStepWillFinish                      = 1 << 6,
    BOTransitionStepFinished                        = 1 << 7,
    
    BOTransitionStepWillCancel                      = 1 << 8,
    BOTransitionStepCancelled                       = 1 << 9,
    
    BOTransitionStepInteractiveEnd                  = 1 << 10,
};

typedef struct {
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
@class BOTransitionGesture;

NS_ASSUME_NONNULL_BEGIN

@protocol BOTransitionEffectControl <NSObject>

@optional

@property (nonatomic, readwrite, nullable, strong) NSDictionary *configInfo;

/*
 弃用，但如果使用者实现了这个，但没实现新的，暂时还能用
 */
- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements API_DEPRECATED("replacement bo_transitioning:prepareForStep:transitionInfo:elements:subInfo:", ios(2.0, 3.0));

/*
 实现这个后只调用这个
 */
- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements
                 subInfo:(nullable NSDictionary *)subInfo;

/*
 不实现的默认情况下，竖滑整个container高代表全程，横滑整个container的宽代表全程
 0-1.0 用作比例
 return @(CGFloat)
 */
- (nullable NSNumber *)bo_transitioning:(BOTransitioning *)transitioning
              distanceCoefficientForGes:(BOTransitionGesture *)gesture;

/*
 不实现的默认情况下，竖滑整个container高代表全程，横滑整个container的宽代表全程
 这里可以返回参考的size
 */
- (nullable NSValue *)bo_transitioning:(BOTransitioning *)transitioning
                  controlCalculateSize:(BOTransitionGesture *)gesture;

/*
 根据当前的ges计算转场的进度，若实现，可以介入和指定percent。不实现或返回nil时使用内置默认行为
 return @(CGFloat)
 */
- (nullable NSNumber *)bo_transitioningGetPercent:(BOTransitioning *)transitioning
                                          gesture:(BOTransitionGesture *)gesture;

/*
 控制当前percent和手势是否应该完成转场或是取消转场，不实现或返回nil时使用内置默认行为
 @intentComplete 手势有速度时，会给出一个倾向性的建议，倾向结束@(YES) 倾向取消@(NO), 无速度或速度很小无倾向nil
 @return @(BOOL)
 */
- (nullable NSNumber *)bo_transitioningShouldFinish:(BOTransitioning *)transitioning
                                    percentComplete:(CGFloat)percentComplete
                                     intentComplete:(NSNumber *)intentComplete
                                            gesture:(BOTransitionGesture *)gesture;

/*
 通用背景蒙层被点击
 */
- (nullable NSDictionary *)bo_transitioning:(BOTransitioning *)transitioning
                             didTapCommonBg:(UIView *)bgView
                                    subInfo:(nullable NSDictionary *)subInfo;

/*
 目前暂只支持一个，后续扩展
 moveIn时，问base获取from，问move获取to
 moveOut时，问move获取from，问base获取to
 */
- (nullable NSArray<NSDictionary *> *)bo_transitioningGetTransViewAr:(BOTransitioning *)transitioning
                                                          fromViewAr:(nullable NSArray<NSDictionary *> *)fromViewAr
                                                             subInfo:(nullable NSDictionary *)subInfo;

@end

@protocol BOTransitionConfigDelegate <BOTransitionEffectControl>

@optional

/*
 当该手势触发时，是否需要以该手势为交互，用transitionType展示某个VC
 return param:
 
 vc/moveInBlock二选一，都选优先vc
 {
 vc: 要入场的vc，
 moveInBlock: ^{
 //如果业务方去自己pushvc，请在这个block中保障pushVC、present等的调用
 },
 act: @"fail" 手势判定不符合，直接cancel该手势
 }
 
 返回suspend时，不做任何操作，不cancel手势，允许手势变化时再询问
 返回nil时，默认行为和不实现一样
 */
- (nullable NSDictionary *)bo_trans_moveInVCWithGes:(BOTransitionGesture *)gesture
                                     transitionType:(BOTransitionType)transitionType
                                            subInfo:(nullable NSDictionary *)subInfo;

/*
 当该手势触发时，是否需要退场该viewController
 不实现该方法默认是@(YES)，想要不干涉需要返回@(YES)
 nil: 不触发退场，但不排除该手势继续滑动，一会儿当触发了某个方向时会继续尝试触发
 YES: 触发交互式退场
 NO: 不可以开始并且取消本次手势响应
 */
- (nullable NSNumber *)bo_trans_shouldMoveOutVC:(UIViewController *)viewController
                                        gesture:(UIGestureRecognizer *)gesture
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
                      gesture:(UIGestureRecognizer *)gesture
               transitionType:(BOTransitionType)transitionType
                      subInfo:(nullable NSDictionary *)subInfo;

/*
 在手势之初，是否接收该手势(只有在两个页面栈容器冲突时才会调用，比如一个nc的子VC中嵌套了另一个nc)
 subInfo:
 "nc" UINavigationController //如果是BOTransitionTypeNavigation的话
 
 return:
 nil不控制，使用默认行为
 @(NO)，终止该手势
 @(YES)，允许该手势
 */
- (nullable NSNumber *)bo_trans_shouldRecTransitionGes:(UIGestureRecognizer *)gesture
                                        transitionType:(BOTransitionType)transitionType
                                               subInfo:(nullable NSDictionary *)subInfo;

@end

NS_ASSUME_NONNULL_END

#endif /* BOTransitionProtocol_h */
