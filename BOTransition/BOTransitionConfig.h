//
//  BOTransitionConfig.h
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BOTransitionEffectControl;
@protocol BOTransitionConfigDelegate;

typedef NSString *BOTransitionEffect NS_EXTENSIBLE_STRING_ENUM;

FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectElementExpension;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectElementExpensionPinGes;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectElementExpensionNoGes;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectElementExpensionOnlyEle;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectPopCard;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectPhotoPreview;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectPhotoPreviewPinGes;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectMoving;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectFade;

@interface BOTransitionConfig : NSObject

+ (instancetype)makeConfig:(void (^)(BOTransitionConfig * _Nonnull config))make;

+ (instancetype)configWithEffect:(nullable BOTransitionEffect)effect;

+ (instancetype)configWithEffect:(nullable BOTransitionEffect)effect
                       startView:(nullable UIView *)startView;

+ (instancetype)configWithEffect:(nullable BOTransitionEffect)effect
                       startView:(nullable UIView *)startView
                  applyToPresent:(BOOL)applyToPresent
                  overTheContext:(BOOL)overTheContext;

+ (instancetype)configWithEffectInfo:(nullable NSDictionary *)effectInfo;

/*
 弹出新VC时，如果上一个VC要提供一些内容，可以使用baseVCDelegate
 */
@property (nonatomic, weak) id<BOTransitionEffectControl> baseVCDelegate;

/*
 BOTransitionConfig是附在一个VC上1对1的，configDelegate可以提供一些关于该VC的配置信息
 */
@property (nonatomic, weak) id<BOTransitionConfigDelegate> configDelegate;


//是否使用系统原生的出/入场方式
@property (nonatomic, assign) BOOL moveInUseOrigin;
@property (nonatomic, assign) BOOL moveOutUseOrigin;

//留作扩展
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

@property (nonatomic, weak) UIView *startViewFromBaseVC;

@property (nonatomic, strong, nullable) BOTransitionEffect transitionEffect;

/*
 {
 BOTransitionEffectElementExpension: @{
 @"style": @"ElementExpension",
 @"config": @{
 @"pinGes": @(NO),
 @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
 },
 
 @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
 },
 
 BOTransitionEffectMoving: @{
 @"style": @"Moving",
 @"config": @{
 @"direction": @(UIRectEdgeRight),
 },
 
 //根据gesTriggerDirection预设moveOutGesDirection
 @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionRight),
 //会执行该configBlock
 @"configBlock": ^(BOTransitionConfig *config) {
 config.moveOutSeriousGes = YES;
 },
 },
 
 BOTransitionEffectFade: @{
 @"style": @"Fade",
 },
 }
 */
@property (nonatomic, strong, nullable) NSDictionary *moveInEffectConfig;
@property (nonatomic, strong, nullable) NSDictionary *moveOutEffectConfig;

/*
 when Ges Interactive,
 use moveOutEffectConfigForInteractive first,
 If you don't have moveOutEffectConfigForInteractive,
 use moveOutEffectConfig
 */
@property (nonatomic, strong, nullable) NSDictionary *moveOutEffectConfigForInteractive;

+ (NSDictionary *)effectDicForEffect:(BOTransitionEffect)transitionEffect;

/*
 支持的moveOut弹出手势方向
 比如想同时支持右滑和下滑可以设置为：
 UISwipeGestureRecognizerDirectionRight|UISwipeGestureRecognizerDirectionDown
 (考虑到moveIn的一般是比较个性化的手势需求，使用configDelegate去定义，不支持快捷属性)
 default: UISwipeGestureRecognizerDirectionRight
 */
@property (nonatomic, assign) UISwipeGestureRecognizerDirection moveOutGesDirection;

/*
 YES: 严格的手势触发条件，手势的开始位置必须在屏幕边缘，手势的开始方向必须与trigger方向相同，
 手势开始后，不触发或取消页面内其他手势，YES只支出UISwipeGestureRecognizerDirectionLeft和Right，因为上下有系统的浮窗
 NO : 宽松的手势触发条件，只要在手势过程中有moveOutGesDirection的方向即可触发转场，
 与页面内其他手势不互斥，可以先完成页面内的scrollView的滑动，再触发moveOut手势
 default: YES
 
 note: YES时moveOutGesDirection必须是横向的，因为会判断屏幕边缘滑入，从上或从下滑入就和系统的面板冲突了。
 */
@property (nonatomic, assign) UISwipeGestureRecognizerDirection moveOutSeriousGesDirection;

/*
 如果修改了bo_transitionConfig中的applyToModalPresentation/presentoverTheContext值，
 请重新对viewControllerset bo_transitionConfig
 
 用于在presentation进行响应
 */
@property (nonatomic, assign) BOOL applyToModalPresentation;
@property (nonatomic, assign) BOOL presentOverTheContext;

/*
 交互结束后，一般会播放一段动画完成全部转场，动画过程是否允许再次按下手指打断动画进行再次交互
 default：NO
 */
@property (nonatomic, assign) BOOL allowInteractionInAnimating;

/*
 该属性不属于本类管理
 这里只是提供一个挂载的位置，让UIViewControllerTransitioningDelegate有地方存储
 */
@property (nonatomic, strong, nullable) id<UIViewControllerTransitioningDelegate> presentTransitioningDelegate;

@end

NS_ASSUME_NONNULL_END
