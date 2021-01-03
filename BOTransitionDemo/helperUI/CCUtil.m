//
//  CCUtil.m
//  VoiceCall
//
//  Created by bo on 29/12/2017.
//  Copyright © 2017 SecretLisa. All rights reserved.
//

#import "CCUtil.h"
#import <objc/runtime.h>

NSMutableDictionary *cc_globalDictionary;

__attribute__((constructor))
static void cc_link() {
    cc_globalDictionary = [NSMutableDictionary new];
}

CGFloat cc_clip(CGFloat min, CGFloat max, CGFloat v)
{
    return MAX(min, MIN(max, v));
}

CGFloat cc_lerp(CGFloat v0, CGFloat v1, CGFloat t)
{
    return v0 + (v1 - v0) * t;
}

UIImage *cc_blurImage(UIImage *image, CGFloat radius)
{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage= [CIImage imageWithCGImage:image.CGImage];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey]; [filter setValue:@(radius) forKey: @"inputRadius"];
    
    CIImage *result=[filter valueForKey:kCIOutputImageKey];
    CGFloat scale = image.scale;
    CGImageRef outImage=[context createCGImage:result fromRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
    UIImage *blurImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    return blurImage;
}

NSURL *cc_urlWithString(NSString *str)
{
    if ([str isKindOfClass:[NSString class]] && str.length > 0) {
        return [NSURL URLWithString:str];
    } else {
        return nil;
    }
}

void cc_runBackgroundThread(void (^bgBlock)(void), void (^finishInMain)(void))
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        bgBlock();
        dispatch_async(dispatch_get_main_queue(), ^{
            finishInMain();
        });
    });
}

@implementation CCBlockWrapper

+ (CCBlockWrapper *(^)(void (^)(id)))wrapperObj
{
    return ^(void (^block)(id)){
        CCBlockWrapper *wp = [CCBlockWrapper new];
        wp.thingsToDo = block;
        return wp;
    };
}

@end

@implementation UIView (cc)

- (UIView *(^)(UIView *))addSubview
{
    return ^(UIView *view) {
        [self addSubview:view];
        return self;
    };
}

- (NSArray *(^)(void (^block)(MASConstraintMaker *make)))mas_makeConstraints
{
    return ^(void (^block)(MASConstraintMaker *make)) {
        return [self mas_makeConstraints:block];
    };
}

- (void (^)(void))cc_setLayoutFitSelf
{
    return ^{
        [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    };
}

@end

@implementation UILabel (cc)

+ (UILabel *(^)(NSString *, UIFont *, UIColor *))cc_label
{
    return ^(NSString *text, UIFont *font, UIColor *color){
        UILabel *label = [UILabel new];
        label.text = text;
        label.font = font;
        label.textColor = color;
        return label;
    };
}

- (UILabel *(^)(UIFont *, UIColor *))cc_setFormat
{
    return ^(UIFont *font, UIColor *textColor) {
        self.font = font;
        self.textColor = textColor;
        return self;
    };
}

@end

@implementation NSString (cc)

- (NSString *)cc_stringByReplaceExtension:(NSString *)extension
{
    if (extension) {
        return [[self stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
    } else {
        return self;
    }
}

@end

@implementation UIButton (cc)

- (UIButton *(^)(void (^)(UIButton *)))cc_setTouchUpInSideDo
{
    return ^(void (^block)(UIButton *)) {
        [self cc_setTouchUpInSideDo:block];
        return self;
    };
}

- (void)cc_setTouchUpInSideDo:(void (^)(UIButton *))block
{
    NSNumber *hastarget = objc_getAssociatedObject(self, @selector(cc_setTouchUpInSideDo:));
    if (nil == hastarget && !hastarget.boolValue) {
        [self addTarget:self action:@selector(cc_buttonTouchUpInSideDo) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(cc_setTouchUpInSideDo:), [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    objc_setAssociatedObject(self, @selector(cc_buttonTouchUpInSideDo),
                             block, OBJC_ASSOCIATION_COPY);
}

- (void)cc_buttonTouchUpInSideDo
{
    void(^block)(UIButton *) = objc_getAssociatedObject(self, @selector(cc_buttonTouchUpInSideDo));
    if (block) {
        block(self);
    }
}

+ (UIButton *(^)(UIButtonType))cc_button
{
    return ^(UIButtonType type){
        return [self buttonWithType:type];
    };
}

- (UIButton *(^)(NSString *, UIFont *, UIColor *))cc_setTitle
{
    return ^(NSString *title, UIFont *font, UIColor *color) {
        [self setTitle:title forState:UIControlStateNormal];
        self.titleLabel.font = font;
        [self setTitleColor:color forState:UIControlStateNormal];
        return self;
    };
}

- (UIButton *(^)(NSString *))cc_setBgImageWithName
{
    return ^(NSString *imgname) {
        [self setBackgroundImage:[UIImage imageNamed:imgname] forState:UIControlStateNormal];
        return self;
    };
}

- (UIButton *(^)(UIImage *))cc_setBgImage
{
    return ^(UIImage *image) {
        [self setBackgroundImage:image forState:UIControlStateNormal];
        return self;
    };
}

@end

@implementation UIViewController (cc)

- (void)setCc_contentInset:(UIEdgeInsets)cc_contentInset
{
    NSValue *value = [NSValue value:&cc_contentInset withObjCType:@encode(UIEdgeInsets)];
    objc_setAssociatedObject(self, @selector(cc_contentInset), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)cc_contentInset
{
    NSValue* value = objc_getAssociatedObject(self, @selector(cc_contentInset));
    UIEdgeInsets insets = UIEdgeInsetsZero;
    [value getValue:&insets];
    return insets;
}

@end

@implementation UIApplication (cc)

- (void)cc_openURL:(id)url options:(NSDictionary<NSString *,id> *)options completionHandler:(void (^)(BOOL))completion
{
    if (!url) return;
    
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:url];
    }
    if (!url) return;
    if (![url isKindOfClass:[NSURL class]]) return;
    
    
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:options completionHandler:completion];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
