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
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectMovingRight;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectMovingBottom;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectFade;
FOUNDATION_EXTERN BOTransitionEffect const BOTransitionEffectAndroidStyle1;

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
 BOTransitionConfig是附在一个VC上1对1的，configDelegate可以提供一些关于该VC的配置信息，若VC有BOTransitionConfig，但configDelegate是nil
 组件会自动尝试把vc当做configDelegate执行代理方法
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

@property (nonatomic, strong, nullable) NSDictionary *moveInEffectConfigForInteractive;

+ (NSDictionary *)effectDicForEffect:(BOTransitionEffect)transitionEffect;

/*
 附着在本config所属的vc上的手势转场，一个NSDictionary代表一个手势方向和对应的事件（比如弹出页面，或者弹出页面）
 direction: UISwipeGestureRecognizerDirection(NSUInteger) //触发的方向
 margin: @(YES/NO) nil=NO //是否必须在边缘开始, YES时会优先其他scrollView进行相应
 allowBeganWithSVBounces: @(YES/NO)
 act: @(1/2) 1moveout(把当前vc关闭)  2movein（从当前vc弹出一个新vc）
 effectConfig: EffectConfig dictionary
 */
@property (nonatomic, readonly, nullable) NSMutableArray<NSDictionary *> *gesInfoAr;

- (void)addGesInfoMoveOut:(BOOL)moveOut
                direction:(UISwipeGestureRecognizerDirection)direction
            seriousMargin:(BOOL)seriousMargin
                 userInfo:(nullable NSDictionary *)userInfo;

//移除指定手势
- (void)removeGesInfo:(NSDictionary *)gesInfo;

//移除所有的moveout/movein手势
- (void)removeGesInfoWithMoveOut:(BOOL)moveOut;

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
