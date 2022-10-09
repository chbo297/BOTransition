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

@property (nonatomic, readwrite, nullable, strong) NSDictionary *configInfo;

- (void)bo_transitioning:(BOTransitioning *)transitioning
          prepareForStep:(BOTransitionStep)step
          transitionInfo:(BOTransitionInfo)transitionInfo
                elements:(NSMutableArray<BOTransitionElement *> *)elements;

/*
 不实现的默认情况下，竖滑整个container高代表全程，横滑整个container的宽代表全程
 return @(CGFloat)
 */
- (nullable NSNumber *)bo_transitioning:(BOTransitioning *)transitioning
              distanceCoefficientForGes:(BOTransitionPanGesture *)gesture;

/*
 根据当前的ges计算转场的进度，若实现，可以介入和指定percent。不实现或返回nil时使用内置默认行为
 return @(CGFloat)
 */
- (nullable NSNumber *)bo_transitioningGetPercent:(BOTransitioning *)transitioning
                                          gesture:(BOTransitionPanGesture *)gesture;

/*
 控制当前percent和手势是否应该完成转场或是取消转场，不实现或返回nil时使用内置默认行为
 @intentComplete 手势有速度时，会给出一个倾向性的建议，倾向结束@(YES) 倾向取消@(NO), 无速度或速度很小无倾向nil
 @return @(BOOL)
 */
- (nullable NSNumber *)bo_transitioningShouldFinish:(BOTransitioning *)transitioning
                                    percentComplete:(CGFloat)percentComplete
                                     intentComplete:(NSNumber *)intentComplete
                                            gesture:(BOTransitionPanGesture *)gesture;

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
 
 返回nil或nsdictionary没内容时，不做任何操作，不cancel手势，允许手势变化时再询问
 */
- (nullable NSDictionary *)bo_trans_moveInVCWithGes:(BOTransitionPanGesture *)gesture
                                     transitionType:(BOTransitionType)transitionType
                                            subInfo:(nullable NSDictionary *)subInfo;

/*
 当该手势触发时，是否需要退场该viewController
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
