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

BOTransitionEffect const BOTransitionEffectMovingRight = @"MovingRight";
BOTransitionEffect const BOTransitionEffectMovingBottom = @"MovingBottom";

BOTransitionEffect const BOTransitionEffectFade = @"Fade";

BOTransitionEffect const BOTransitionEffectAndroidStyle1 = @"AndroidStyle1";

@interface BOTransitionConfig ()

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *gesInfoAr;

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
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionRight
                                seriousMargin:YES
                                     userInfo:nil];
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
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionRight
                                seriousMargin:YES
                                     userInfo:nil];
                },
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
        
        BOTransitionEffectPopCard: @{
                @"style": @"ElementExpension",
                @"config": @{
                        @"pinGes": @(NO),
                        @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                        @"onlyBoard": @(YES),
                },
        },
        
        BOTransitionEffectMovingRight: @{
                @"style": @"Moving",
                @"config": @{
                        @"direction": @(UIRectEdgeRight),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionRight
                                seriousMargin:YES
                                     userInfo:nil];
                },
        },
        
        BOTransitionEffectMovingBottom: @{
                @"style": @"Moving",
                @"config": @{
                        @"direction": @(UIRectEdgeBottom),
                },
                
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
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
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionRight
                                seriousMargin:YES
                                     userInfo:nil];
                },
                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
        
        BOTransitionEffectPhotoPreviewPinGes: @{
                @"style": @"PhotoPreview",
                @"config": @{
                        @"freePinGes": @(YES),
//                        @"disablePinGesForDirection": @(UISwipeGestureRecognizerDirectionRight),
                },
                
                @"configBlock": ^(BOTransitionConfig *config) {
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionRight
                                seriousMargin:NO
                                     userInfo:@{
                        @"allowBeganWithSVBounces": @(YES),
                        @"allowOtherSVDirectionCoexist": @(YES)
                    }];
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionLeft
                                seriousMargin:NO
                                     userInfo:@{
                        @"allowBeganWithSVBounces": @(YES),
                        @"allowOtherSVDirectionCoexist": @(YES)
                    }];
                     [config addGesInfoMoveOut:YES
                                     direction:UISwipeGestureRecognizerDirectionUp
                                 seriousMargin:NO
                                      userInfo:@{
                        @"allowBeganWithSVBounces": @(YES),
                        @"allowOtherSVDirectionCoexist": @(YES)
                    }];
                     [config addGesInfoMoveOut:YES
                                     direction:UISwipeGestureRecognizerDirectionDown
                                 seriousMargin:NO
                                      userInfo:@{
                        @"allowBeganWithSVBounces": @(YES),
                        @"allowOtherSVDirectionCoexist": @(YES)
                    }];
                },
//                @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
        },
        
        BOTransitionEffectAndroidStyle1: @{
                @"style": @"AndroidStyle1",
                @"configBlock": ^(BOTransitionConfig *config) {
                    [config addGesInfoMoveOut:YES
                                    direction:UISwipeGestureRecognizerDirectionRight
                                seriousMargin:YES
                                     userInfo:nil];
                },
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
            [self addGesInfoMoveOut:YES
                          direction:gesTriggerDirectionval.unsignedIntegerValue
                      seriousMargin:NO userInfo:nil];
        }
        
        void (^configblock)(BOTransitionConfig *config) = infoDic[@"configBlock"];
        if (configblock) {
            configblock(self);
        }
    }
}

- (void)addGesInfoMoveOut:(BOOL)moveOut
                direction:(UISwipeGestureRecognizerDirection)direction
            seriousMargin:(BOOL)seriousMargin
                 userInfo:(NSDictionary *)userInfo {
    if (!_gesInfoAr) {
        _gesInfoAr = @[].mutableCopy;
    }
    
    NSMutableDictionary *mudic = @{
        @"act": @(moveOut ? 1 : 2),
        @"direction": @(direction),
        @"margin": @(seriousMargin)
    }.mutableCopy;
    
    if (userInfo
        && userInfo.count > 0) {
        [mudic addEntriesFromDictionary:userInfo];
    }
    
    //后加的优先判定：放在数组头部
    [_gesInfoAr insertObject:mudic atIndex:0];
}

- (void)removeGesInfoWithMoveOut:(BOOL)moveOut {
    NSMutableArray *toremovear = @[].mutableCopy;
    
    NSInteger removeact = moveOut ? 1 : 2;
    [_gesInfoAr enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *actnum = [obj objectForKey:@"act"];
        if (nil != actnum
            && actnum.integerValue == removeact) {
            [toremovear addObject:obj];
        }
    }];
    
    if (toremovear.count > 0) {
        [_gesInfoAr removeObjectsInArray:toremovear];
    }
    
    if (0 == _gesInfoAr.count) {
        _gesInfoAr = nil;
    }
}

- (void)removeGesInfo:(NSDictionary *)gesInfo {
    if (!gesInfo) {
        return;
    }
    
    [_gesInfoAr removeObject:gesInfo];
    if (0 == _gesInfoAr.count) {
        _gesInfoAr = nil;
    }
}

@end
