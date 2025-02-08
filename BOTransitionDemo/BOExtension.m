//
//  BOExtension.m
//  VirtualCall
//
//  Created by bo on 2022/9/11.
//

#import "BOExtension.h"
#import <objc/runtime.h>

void bo_swizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation UIView (BOExtension)

- (void)setBo_frame:(CGRect)bo_frame {
    if (!CGRectEqualToRect(bo_frame, self.frame)) {
        [self setFrame:bo_frame];
    }
}

- (CGRect)bo_frame {
    return self.frame;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bo_swizzleMethod([self class],
                         @selector(pointInside:withEvent:),
                         @selector(bo_pointInside:withEvent:));
        bo_swizzleMethod([self class],
                         @selector(hitTest:withEvent:),
                         @selector(bo_hitTest:withEvent:));
        bo_swizzleMethod([self class],
                         @selector(layoutSubviews),
                         @selector(bo_layoutSubviews));
//        bo_swizzleMethod([self class],
//                         @selector(intrinsicContentSize),
//                         @selector(bo_intrinsicContentSize));
    });
}

- (UIView * _Nullable (^)(UIView * _Nonnull, CGPoint, UIEvent * _Nullable, UIView * _Nullable (^ _Nonnull)(CGPoint, UIEvent * _Nullable)))bo_hitTestHook {
    return objc_getAssociatedObject(self, @selector(bo_hitTestHook));
}

- (void)setBo_hitTestHook:(UIView * _Nullable (^)(UIView * _Nonnull,
                                                  CGPoint,
                                                  UIEvent * _Nullable,
                                                  UIView * _Nullable (^ _Nonnull)(CGPoint,
                                                                                  UIEvent * _Nullable)))bo_hitTestHook {
    objc_setAssociatedObject(self, @selector(bo_hitTestHook),
                             bo_hitTestHook, OBJC_ASSOCIATION_COPY);
}

- (UIView *)bo_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.bo_hitTestHook) {
        UIView* (^oriimp)(CGPoint,
                          UIEvent * _Nullable) = ^(CGPoint point,
                                                   UIEvent * _Nullable event) {
                              return [self bo_hitTest:point withEvent:event];
                          };
        
        return self.bo_hitTestHook(self, point, event, oriimp);
    } else {
        return [self bo_hitTest:point withEvent:event];
    }
}

//- (NSValue *)bo_fixIntrinsicContentSize {
//    NSValue *value = objc_getAssociatedObject(self, @selector(bo_fixIntrinsicContentSize));
//    return value;
//}
//
//- (void)setBo_fixIntrinsicContentSize:(NSValue *)bo_fixIntrinsicContentSize {
//    objc_setAssociatedObject(self, @selector(bo_fixIntrinsicContentSize),
//                             bo_fixIntrinsicContentSize,
//                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}
//
//- (CGSize)bo_intrinsicContentSize {
//    if (self.bo_fixIntrinsicContentSize) {
//        return self.bo_fixIntrinsicContentSize.CGSizeValue;
//    } else {
//        return [self bo_intrinsicContentSize];
//    }
//}

- (UIEdgeInsets)bo_pointInsideExtension {
    NSValue *value = objc_getAssociatedObject(self, @selector(bo_pointInsideExtension));
    UIEdgeInsets insets = UIEdgeInsetsZero;
    [value getValue:&insets];
    return insets;
}

- (void)setBo_pointInsideExtension:(UIEdgeInsets)bo_pointInsideExtension {
    NSValue *value = [NSValue value:&bo_pointInsideExtension withObjCType:@encode(UIEdgeInsets)];
    objc_setAssociatedObject(self, @selector(bo_pointInsideExtension),
                             value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber * (^)(CGRect, CGPoint, UIEvent *))bo_pointInsideJudge {
    return objc_getAssociatedObject(self, @selector(bo_pointInsideJudge));
}

- (void)setBo_pointInsideJudge:(NSNumber * (^)(CGRect, CGPoint, UIEvent *))bo_pointInsideJudge {
    objc_setAssociatedObject(self, @selector(bo_pointInsideJudge),
                             bo_pointInsideJudge, OBJC_ASSOCIATION_COPY);
}

- (BOOL)bo_pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    if (self.bo_pointInsideJudge) {
        NSNumber *judge = self.bo_pointInsideJudge(self.bounds, point, event);
        if (nil != judge) {
            return judge.boolValue;
        }
    }
    
    UIEdgeInsets insets = self.bo_pointInsideExtension;
    if (UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero)) {
        return [self bo_pointInside:point withEvent:event];
    } else {
        CGRect hitBounds = UIEdgeInsetsInsetRect(self.bounds, insets);
        return CGRectContainsPoint(hitBounds, point);
    }
}

- (void)bo_layoutSubviews {
    [self bo_layoutSubviews];
    
    CGSize currsize = self.bounds.size;
    NSValue *value =\
    objc_getAssociatedObject(self,
                             @selector(bo_layoutSubviewsOnlySizeChange:subInfo:));
    if (nil != value) {
        CGSize lastsize = CGSizeZero;
        [value getValue:&lastsize];
        if (CGSizeEqualToSize(lastsize, currsize)) {
            return;
        }
    }
    
    value = [NSValue value:&currsize withObjCType:@encode(CGSize)];
    objc_setAssociatedObject(self,
                             @selector(bo_layoutSubviewsOnlySizeChange:subInfo:),
                             value,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self bo_layoutSubviewsOnlySizeChange:currsize subInfo:nil];
    
}

- (void)bo_layoutSubviewsOnlySizeChange:(CGSize)currSize
                                subInfo:(nullable NSDictionary *)subInfo {
    
}

@end

@implementation UIViewController (BOExtension)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bo_swizzleMethod([self class],
                         @selector(viewDidLayoutSubviews),
                         @selector(bo_viewDidLayoutSubviews));
    });
}

- (void)bo_viewDidLayoutSubviews {
    [self bo_viewDidLayoutSubviews];
    
    CGSize currsize = self.view.bounds.size;
    NSValue *value =\
    objc_getAssociatedObject(self,
                             @selector(bo_viewDidLayoutSubviewsOnlySizeChange:subInfo:));
    if (nil != value) {
        CGSize lastsize = CGSizeZero;
        [value getValue:&lastsize];
        if (CGSizeEqualToSize(lastsize, currsize)) {
            return;
        }
    }
    
    value = [NSValue value:&currsize withObjCType:@encode(CGSize)];
    objc_setAssociatedObject(self,
                             @selector(bo_layoutSubviewsOnlySizeChange:subInfo:),
                             value,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self bo_viewDidLayoutSubviewsOnlySizeChange:currsize subInfo:nil];
}

/*
 只有在首次和size发生变化才调用该方法
 super什么也没做，若清楚该方法的机制，重写该方法是可选择不调用super也可
 */
- (void)bo_viewDidLayoutSubviewsOnlySizeChange:(CGSize)currSize
                                       subInfo:(nullable NSDictionary *)subInfo {
    
}

@end


@implementation NSDictionary (BOExtension)

- (NSArray *)bo_arrayForKey:(id)key {
    id ret = [self objectForKey:key];
    if ([ret isKindOfClass:[NSArray class]]) {
        return ret;
    }
    return nil;
}

- (NSMutableDictionary *)bo_mutableDictionaryForKey:(id)key {
    id ret = [self objectForKey:key];
    if ([ret isKindOfClass:[NSMutableDictionary class]]) {
        return ret;
    }
    return nil;
}

- (NSDictionary *)bo_dictionaryForKey:(id)key {
    id ret = [self objectForKey:key];
    if ([ret isKindOfClass:[NSDictionary class]]) {
        return ret;
    }
    return nil;
}

- (NSString *)bo_stringForKey:(id)key {
    id ret = [self objectForKey:key];
    if ([ret isKindOfClass:[NSString class]]) {
        return ret;
    } else if ([ret isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", ret];
    }
    return nil;
}

- (NSValue *)bo_nsValueForKey:(id)key {
    id ret = [self objectForKey:key];
    if ([ret isKindOfClass:[NSValue class]]) {
        return ret;
    }
    return nil;
}

- (NSNumber *)bo_numberForKey:(id)key {
    id ret = [self objectForKey:key];
    if ([ret isKindOfClass:[NSNumber class]]) {
        return ret;
    } else if ([ret isKindOfClass:[NSString class]]) {
        static NSNumberFormatter* formatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
        });
        
        NSNumber *number = [formatter numberFromString:ret];
        if (number == nil) {
            //兼容true和false字符串
            NSDictionary<NSString *, NSNumber *>* str_num_dic = @{
                @"true": @(YES),
                @"True": @(YES),
                @"false": @(NO),
                @"False": @(NO),
            };
            number = [str_num_dic objectForKey:ret];
        }
        
        return number;
    }
    
    return nil;
}

- (BOOL)bo_boolValueForKey:(id)key {
    return [self bo_numberForKey:key].boolValue;
}

- (NSInteger)bo_integerValueForKey:(id)key {
    return [self bo_numberForKey:key].integerValue;
}

- (float)bo_floatValueForKey:(id)key {
    return [self bo_numberForKey:key].floatValue;
}

- (double)bo_doubleValueForKey:(id)key {
    return [self bo_numberForKey:key].doubleValue;
}

@end

