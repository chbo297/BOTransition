//
//  BOTransitionConfig.m
//  BOTransition
//
//  Created by bo on 2020/11/10.
//  Copyright © 2020 bo. All rights reserved.
//

#import "BOTransitionConfig.h"

BOTransitionEffect const BOTransitionEffectElementExpension = @"ElementExpension";
BOTransitionEffect const BOTransitionEffectElementExpensionPinGes = @"ElementExpensionPinGes";
BOTransitionEffect const BOTransitionEffectElementExpensionNoGes = @"ElementExpensionNoGes";
BOTransitionEffect const BOTransitionEffectElementExpensionOnlyEle = @"ElementExpensionOnlyEle";

BOTransitionEffect const BOTransitionEffectPopCard = @"PopCard";

BOTransitionEffect const BOTransitionEffectPhotoPreview = @"PhotoPreview";
BOTransitionEffect const BOTransitionEffectPhotoPreviewPinGes = @"PhotoPreviewPinGes";

BOTransitionEffect const BOTransitionEffectMoving = @"Moving";

BOTransitionEffect const BOTransitionEffectFade = @"Fade";

@interface BOTransitionConfig ()

@end

@implementation BOTransitionConfig

+ (instancetype)makeConfig:(void (^)(BOTransitionConfig * _Nonnull))make {
    BOTransitionConfig *config = [BOTransitionConfig new];
    if (make) {
        make(config);
    }
    
    return config;
}

+ (instancetype)configWithEffect:(BOTransitionEffect _Nullable)effect {
    BOTransitionConfig *config = [BOTransitionConfig new];
    config.transitionEffect = effect;
    return config;
}

+ (instancetype)configWithEffect:(BOTransitionEffect _Nullable)effect
                       startView:(UIView * _Nullable)startView {
    BOTransitionConfig *config = [BOTransitionConfig new];
    config.startViewFromBaseVC = startView;
    config.transitionEffect = effect;
    return config;
}

+ (instancetype)configWithEffect:(BOTransitionEffect _Nullable)effect
                       startView:(UIView * _Nullable)startView
                  applyToPresent:(BOOL)applyToPresent
                  overTheContext:(BOOL)overTheContext {
    BOTransitionConfig *config = [BOTransitionConfig new];
    config.startViewFromBaseVC = startView;
    config.transitionEffect = effect;
    config.applyToModalPresentation = applyToPresent;
    config.presentOverTheContext = overTheContext;
    return config;
}

+ (instancetype)configWithEffectInfo:(nullable NSDictionary *)effectInfo {
    BOTransitionConfig *config = [BOTransitionConfig new];
    config.moveInEffectConfig = effectInfo;
    config.moveOutEffectConfig = effectInfo;
    return config;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _moveOutGesDirection = 0;
        _moveOutSeriousGesDirection = 0;
        _applyToModalPresentation = YES;
    }
    return self;
}

+ (NSDictionary *)effectDicForEffect:(BOTransitionEffect)transitionEffect {
    NSDictionary *defaultdic = @{
        BOTransitionEffectElementExpension: @{
                @"style": @"ElementExpension",
                @"config": @{
                        @"bg": @(NO),
                        @"pinGes": @(NO),
                        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    config.moveOutSeriousGesDirection = UISwipeGestureRecognizerDirectionRight;
                },
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
        
        BOTransitionEffectElementExpensionPinGes: @{
                @"style": @"ElementExpension",
                @"config": @{
                        @"pinGes": @(YES),
                        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    config.moveOutSeriousGesDirection = 0;
                },
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
        
        BOTransitionEffectElementExpensionNoGes: @{
                @"style": @"ElementExpension",
                @"config": @{
                        @"pinGes": @(NO),
                        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                },
        },
        
        BOTransitionEffectElementExpensionOnlyEle: @{
                @"style": @"ElementExpension",
                @"config": @{
                        @"bg": @(NO),
                        @"pinGes": @(NO),
                        @"disableBoardMove": @(YES),
                        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                },
                
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionRight),
        },
        
        BOTransitionEffectPopCard: @{
                @"style": @"ElementExpension",
                @"config": @{
                        @"pinGes": @(NO),
                        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                        @"onlyBoard": @(YES),
                },
        },
        
        BOTransitionEffectMoving: @{
                @"style": @"Moving",
                @"config": @{
                        @"direction": @(UIRectEdgeRight),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    config.moveOutSeriousGesDirection = UISwipeGestureRecognizerDirectionRight;
                },
        },
        
        BOTransitionEffectFade: @{
                @"style": @"Fade",
                
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionRight),
        },
        
        BOTransitionEffectPhotoPreview: @{
                @"style": @"PhotoPreview",
                @"config": @{
                        @"pinGes": @(NO),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    config.moveOutSeriousGesDirection = UISwipeGestureRecognizerDirectionRight;
                },
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
        
        BOTransitionEffectPhotoPreviewPinGes: @{
                @"style": @"PhotoPreview",
                @"config": @{
                        @"pinGes": @(YES),
                        @"disablePinGesForDirection": @(UISwipeGestureRecognizerDirectionRight),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    config.moveOutSeriousGesDirection = UISwipeGestureRecognizerDirectionRight;
                },
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
    };
    
    return defaultdic[transitionEffect];
}

- (void)setTransitionEffect:(BOTransitionEffect)transitionEffect {
    _transitionEffect = transitionEffect;
    
    NSDictionary *configinfo = [self.class effectDicForEffect:_transitionEffect];;
    _moveInEffectConfig = configinfo;
    //self. 借助一下moveOutEffectConfig的set方法 加载里面的外层配置
    self.moveOutEffectConfig = configinfo;
}

- (void)setMoveInEffectConfig:(NSDictionary *)moveInEffectConfig {
    _moveInEffectConfig = moveInEffectConfig;
    [self loadInfoFromEffectConfig:_moveInEffectConfig];
}

- (void)setMoveOutEffectConfig:(NSDictionary *)moveOutEffectConfig {
    _moveOutEffectConfig = moveOutEffectConfig;
    [self loadInfoFromEffectConfig:_moveOutEffectConfig];
}

- (void)setMoveOutEffectConfigForInteractive:(NSDictionary *)moveOutEffectConfigForInteractive {
    _moveOutEffectConfigForInteractive = moveOutEffectConfigForInteractive;
    [self loadInfoFromEffectConfig:_moveOutEffectConfigForInteractive];
}

- (void)loadInfoFromEffectConfig:(NSDictionary *)infoDic {
    if (infoDic.count > 0) {
        NSNumber *gesTriggerDirectionval = infoDic[@"gesTriggerDirection"];
        if (nil != gesTriggerDirectionval) {
            self.moveOutGesDirection = gesTriggerDirectionval.unsignedIntegerValue;
        }
        
        void (^configblock)(BOTransitionConfig *config) = infoDic[@"configBlock"];
        if (configblock) {
            configblock(self);
        }
    }
}

@end
