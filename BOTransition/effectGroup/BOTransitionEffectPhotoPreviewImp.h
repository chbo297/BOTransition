//
//  BOTransitionEffectPhotoPreviewImp.h
//  BOTransitionDemo
//
//  Created by bo on 2021/1/3.
//

#import "BOTransitionProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@protocol BOTransitionEffectControl;

@interface BOTransitionEffectPhotoPreviewImp : NSObject <BOTransitionEffectControl>

/*
 {
 @"style": @"PhotoPreview",
 */
@property (nonatomic, strong, nullable) NSDictionary *configInfo;

@end

NS_ASSUME_NONNULL_END
