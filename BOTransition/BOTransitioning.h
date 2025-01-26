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

/*
 BOTransitionVCViewDidMoveToContainer:
 notification.userInfo:
 "vc": <如果转场成功，即将展示的VC>
 */
UIKIT_EXTERN const NSNotificationName BOTransitionVCViewDidMoveToContainer;

/*
 BOTransitionWillAndMustCompletion:
 notification.userInfo:
 @"finish": @(YES), //YES成功完成，NO被取消(如手势未完成又滑回去了)
 @"vcPt": <如果转场成功，即将展示的VC的%p字符串>
 (该notific会在转场动画提交执行后的下个runloop执行，为了不影响其释放时机，传地址字符串)
 */
UIKIT_EXTERN const NSNotificationName BOTransitionWillAndMustCompletion;

@interface BOTransitioning : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

@property (nonatomic, readonly) BOTransitionType transitionType;

+ (instancetype)transitioningWithType:(BOTransitionType)transitionType;

- (instancetype)initWithTransitionType:(BOTransitionType)transitionType NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

//present/push动作发生之前前已经在展示的基准VC
@property (nonatomic, readonly, nullable) UIViewController *baseVC;
//present/push动作的入场VC以及 dismiss/pop动作的离场VC
@property (nonatomic, readonly, nullable) UIViewController *moveVC;

/*
 act=moveIn时，start=baseVC，des=moveVC
 act=moveOut时，start=moveVC，des=baseVC
 */
@property (nonatomic, readonly, nullable) UIViewController *startVC;
@property (nonatomic, readonly, nullable) UIViewController *desVC;

//用来转场的容器
@property (nonatomic, readonly, nullable) UIView *baseTransBoard;
@property (nonatomic, readonly, nullable) UIView *moveTransBoard;

@property (nonatomic, readonly, nullable) UIView *commonBg;
@property (nonatomic, readonly) UIView *checkAndInitCommonBg;

@property (nonatomic, readonly) NSString *effectStyle;
@property (nonatomic, weak) BOTransitionConfig *moveVCConfig;

@property (nonatomic, readonly, nonnull) BOTransitionPanGesture *transitionGes;

@property (nonatomic, readonly) BOOL triggerInteractiveTransitioning;

@property (nonatomic, readonly, nullable) id<UIViewControllerContextTransitioning> transitionContext;

//外部控制 每个周期前必须被设置为正确的类型
@property (nonatomic, assign) BOTransitionAct transitionAct;

@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, weak) UITabBarController *tabBarController;

//页面有特殊需要，强制取消当前的转场（只能取消手势型转场）
- (void)forceCancelTransition;

/*
 return:
 1 保留ges
 2 保留otherges
 0 没有判断出结果
 */
+ (NSInteger)checkWithVC:(nullable UIViewController *)vc
          transitionType:(BOTransitionType)transitionType
                makeFail:(BOOL)makeFail
                 baseGes:(UIGestureRecognizer *)ges
      otherTransitionGes:(UIGestureRecognizer *)otherGes;

//控件自己使用，nc的view布局完成后通知BOTransitioning的方法
- (void)ncViewDidLayoutSubviews:(UINavigationController *)nc;

@end

@interface BOTransitionElement : NSObject

/*
 ele可以有子ele
 */
@property (nonatomic, readonly, nullable) NSMutableArray<BOTransitionElement *> *subEleAr;
- (void)addSubElement:(BOTransitionElement *)element;
- (void)removeSubElement:(BOTransitionElement *)element;

@property (nonatomic, weak) BOTransitionElement *superElement;

+ (instancetype)elementWithType:(BOTransitionElementType)type;

@property (nonatomic, assign) BOTransitionElementType elementType;

@property (nonatomic, strong, nullable) UIView *transitionView;
/*
 在开始和结束时，自动添加、移除transitionView，
 default：0
 目前默认会在container中铺满
 0: 不执行添加和移除操作
 <=10: 执行，层级在basevc下边
 <=20: 执行，层级在basevc和movevc中间
 <=30: 执行，层级在movevc上面
 */
@property (nonatomic, assign) NSInteger autoAddAndRemoveTransitionView;


@property (nonatomic, weak) UIView *fromView;
@property (nonatomic, weak) UIView *toView;
@property (nonatomic, strong, nullable) NSValue *toFrameCoordinateInVC;

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
@property (nonatomic, readonly, nonnull) NSMutableDictionary *userInfo;

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
@property (nonatomic, strong, nullable) NSValue *frameLastBeforeAni;

/*
 UIViewAnimationOptions
 不设置默认UIViewAnimationOptionCurveLinear
 */
@property (nonatomic, strong, nullable) NSNumber *aniCurveOpt;

//是否进行alpha转变
@property (nonatomic, assign) BOOL alphaAllow;
//0-1
@property (nonatomic, assign) CGFloat alphaInteractiveLimit;
//暂只支持CalPow方式，若需要更丰富的曲线函数后续再扩展吧
@property (nonatomic, assign) CGFloat alphaCalPow;
@property (nonatomic, assign) CGFloat alphaFrom;
@property (nonatomic, assign) CGFloat alphaTo;
@property (nonatomic, assign) CGFloat alphaOrigin;

/*
 .. 暂无定义，预留字段，给可打断动画使用的，但动画打断的体验不大好先不开启
 */
@property (nonatomic, strong, nullable) NSNumber *alphaLastBeforeAni;

/*
 入参：转场的进度百分比0~1
 返回 应用于该转场元素进行frame、alpha等属性变化的百分比
 */
@property (nonatomic, copy, nullable) CGFloat (^innerPercentWithTransitionPercent)(CGFloat percent);

- (CGFloat)interruptAnimation:(BOTransitionInfo)transitionInfo;
/*
 "aniPercent":
 */
- (void)interruptAnimationAndResetPorperty:(BOTransitioning *)transitioning
                            transitionInfo:(BOTransitionInfo)transitionInfo
                                   subInfo:(nullable NSDictionary *)subInfo;

@end


@interface UIViewController (BOTransitioningContext)

@property (nonatomic, readonly, nullable) BOTransitioning *bo_currentTransitioning;

@end

NS_ASSUME_NONNULL_END
