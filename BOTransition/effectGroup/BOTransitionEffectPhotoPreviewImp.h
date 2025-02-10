//
//  BOTransitionEffectPhotoPreviewImp.h
//  BOTransitionDemo
//
//  Created by bo on 2021/1/3.
//

#import "BOTransitionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*
 "style": @"PhotoPreview",
 */
@interface BOTransitionEffectPhotoPreviewImp : NSObject

/*
 effect_only_finish: "1"
 */
@property (nonatomic, strong, nullable) NSDictionary *configInfo;

@end

NS_ASSUME_NONNULL_END
