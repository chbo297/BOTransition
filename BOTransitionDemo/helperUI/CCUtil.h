//
//  CCUtil.h
//  VoiceCall
//
//  Created by bo on 29/12/2017.
//  Copyright © 2017 SecretLisa. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    extern CGFloat cc_clip(CGFloat min, CGFloat max, CGFloat v);
    
    extern CGFloat cc_lerp(CGFloat v0, CGFloat v1, CGFloat t);
    
    extern NSURL *cc_urlWithString(NSString *str);
    
    extern UIImage *cc_blurImage(UIImage *image, CGFloat radius);
    
    extern void cc_runBackgroundThread(void (^bgBlock)(void), void (^finishInMain)(void));
#ifdef __cplusplus
}
#endif



extern NSMutableDictionary *cc_globalDictionary;

@interface CCBlockWrapper : NSObject

@property (class, nonatomic, readonly) CCBlockWrapper * (^wrapperObj)(void (^block)(id info));

@property (nonatomic, copy) void (^thingsToDo)(id info);

@end

@interface UIView (cc)

//为OC添加链式语法:  view1.addSubView(view2);   view2.mas_makeConstraints(^(MASConstraintMaker *make) {}

@property (nonatomic, readonly) UIView * (^addSubview)(UIView *view);

@property (nonatomic, readonly) NSArray * (^mas_makeConstraints)(void (^block)(MASConstraintMaker *make));

//为View添加fit的布局约束；限制View的横竖方向的拉伸和压缩.
@property (nonatomic, readonly) void (^cc_setLayoutFitSelf)(void);

@end

@interface UILabel (cc)

@property (class, nonatomic, readonly) UILabel * (^cc_label)(NSString *text, UIFont *font, UIColor *color);

@property (nonatomic, readonly) UILabel * (^cc_setFormat)(UIFont *font, UIColor *color);

@end

@interface NSString (cc)

- (NSString *)cc_stringByReplaceExtension:(NSString *)extension;

@end

@interface UIButton (cc)

@property (class, nonatomic, readonly) UIButton * (^cc_button)(UIButtonType type);

@property (nonatomic, readonly) UIButton * (^cc_setBgImage)(UIImage *imgName);
@property (nonatomic, readonly) UIButton * (^cc_setBgImageWithName)(NSString *imgName);
@property (nonatomic, readonly) UIButton * (^cc_setTitle)(NSString *title, UIFont *font, UIColor *color);

@property (nonatomic, readonly) UIButton * (^cc_setTouchUpInSideDo)(void (^block)(UIButton *bt));

@end

@interface UIViewController (cc)

@property (nonatomic, assign) UIEdgeInsets cc_contentInset;

@end

@interface UIApplication (cc)

- (void)cc_openURL:(id)url options:(NSDictionary<NSString *,id> *)options completionHandler:(void (^)(BOOL))completion;

@end


