//
//  BOTransitionPanGesture.h
//  BOTransition
//
//  Created by bo on 2020/11/13.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct BOTransitionGesSliceInfo {
    UISwipeGestureRecognizerDirection mainDirection;
    UISwipeGestureRecognizerDirection subDirection;
    
    CGPoint velocity;
    CGPoint location;
} BOTransitionGesSliceInfo;

typedef struct BOTransitionPanGestureBrief {
    NSArray<NSValue *> *lastTouchInfoAr;
    BOTransitionGesSliceInfo triggerDirectionInfo;
} BOTransitionPanGestureBrief;

@class BOTransitionPanGesture;

@protocol BOTransitionGestureDelegate <NSObject>

@optional

/*
 nil: 不开始，但不排除该手势继续滑动，一会儿当触发了某个方向时会继续尝试触发
 YES: 开始手势
 NO: 不可以开始并且取消本次手势响应
 
 specialDirection: 指定并修改trigger的mainDirection
 
 @{
 @"type": @"needsRecoverWhenTouchDown",
 @"otherSVResponse": @{info: @(CGPoint), gesAr: NSHashTable<UIGestureRecognizer>}见下述
 }
 
 @{info: @(CGPoint), gesAr: NSHashTable<UIGestureRecognizer>}
  一次只支持传一个方向
  info {x, y}
  x:
  0 不能滑动 不能bounces
  1 for  bounces
  2 normal scroll
  
  y:
  1 手势是可能的状态
  2 手势明确启动了
  
 gesAr: NSHashTable<UIGestureRecognizer>
 */
- (nullable NSNumber *)boTransitionGesShouldAndWillBegin:(BOTransitionPanGesture *)ges
                                    specialMainDirection:(UISwipeGestureRecognizerDirection *)mainDirection
                                                 subInfo:(nullable NSDictionary *)subInfo;

- (void)boTransitionGesStateDidChange:(BOTransitionPanGesture *)ges;

/*
 0: 默认（ges内置会共存），不做处理
 1: ges优先
 2: otherGes优先
 3: 不判断，保留原有优先级
 4: ges优先并强制fail掉other
 */
- (NSInteger)boTransitionGRStrategyForGes:(BOTransitionPanGesture *)ges
                                 otherGes:(UIGestureRecognizer *)otherGes;

/*
 用来处理nc嵌套nc之类的情况，两个转场手势的冲突处理
 0 默认行为（内置会根据一些策略fail掉其中一个），不做处理
 1 保留ges
 2 保留otherges
 
 */
- (NSInteger)checkTransitionGes:(UIGestureRecognizer *)tGes
             otherTransitionGes:(UIGestureRecognizer *)otherTGes
                       makeFail:(BOOL)makeFail;

@end

//借用了系统的UIPanGestureRecognizer
@interface BOTransitionPanGesture : UIGestureRecognizer

//首次产生滑动方向时的信息
@property (nonatomic, readonly) BOTransitionGesSliceInfo initialDirectionInfo;

/*
 排除其他scrollView影响后，真正触发本手势时的方向信息，
 若没有其他scrollView影响时
 triggerDirectionInfo = initialDirectionInfo，
 delayByOtherSV = NO
 */
@property (nonatomic, readonly) BOTransitionGesSliceInfo triggerDirectionInfo;

/*
 CGRect
 x, y, 时间戳, 0
 */
@property (nonatomic, readonly) NSMutableArray<NSValue *> *touchInfoAr;

//判断当前是否从变化划入触发的
- (BOOL)calculateIfMarginTrigger;

/*
 @(UISwipeGestureRecognizerDirection): @{info: @(CGPoint), gesAr: NSHashTable<UIGestureRecognizer>}
 
  info {x, y}
  x:
  0 不能滑动 不能bounces
  1 for  bounces
  2 normal scroll
  
  y:
  1 手势是可能的状态
  2 手势明确启动了
  
 gesAr: NSHashTable<UIGestureRecognizer>
 */
@property (nonatomic, readonly, nonnull) NSDictionary<NSNumber *, NSDictionary *> *otherSVRespondedDirectionRecord;
@property (nonatomic, readonly) BOOL delayTrigger;
@property (nonatomic, readonly) BOOL beganWithSVBounces;

@property (nonatomic, readonly) UIGestureRecognizerState transitionGesState;

@property (nonatomic, weak) id<BOTransitionGestureDelegate> transitionGesDelegate;

- (instancetype)initWithTransitionGesDelegate:(nullable id<BOTransitionGestureDelegate>)transitionGesDelegate NS_DESIGNATED_INITIALIZER;

- (void)saveCurrGesContextAndSetNeedsRecoverWhenTouchDown;
- (void)clearSaveContext;

- (void)makeGesStateCanceledButCanRetryBegan;

//若当前有初始点，可以修改，没有时没效果
- (void)insertBeganPt:(CGPoint)beganPt;

- (CGPoint)velocityInCurrView;

//给外部挂信息用，目前内部会在手势结束时清空该信息。
@property (nonatomic, strong, nonnull) NSMutableDictionary *userInfo;

+ (BOOL)tryMakeGesFail:(UIGestureRecognizer *)gesShouldFail
                 byGes:(UIGestureRecognizer *)ges
                 force:(BOOL)force;

/*
 0 不是
 1 navigationController 系统pop
 2 BOTransitionPanGesture
 */
+ (NSInteger)isTransitonGes:(UIGestureRecognizer *)ges;

@end

NS_ASSUME_NONNULL_END
