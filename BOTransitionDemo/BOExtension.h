//
//  BOExtension.h
//  VirtualCall
//
//  Created by bo on 2022/9/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN void bo_swizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector);

@interface UIViewController (BOExtension)

/*
 只有在首次和size发生变化才调用该方法
 super什么也没做，若清楚该方法的机制，重写该方法是可选择不调用super也可
 */
- (void)bo_viewDidLayoutSubviewsOnlySizeChange:(CGSize)currSize
                                       subInfo:(nullable NSDictionary *)subInfo;

@end

@interface UIView (BOExtension)

@property (nonatomic, readwrite) CGRect bo_frame;

@property (nonatomic) UIEdgeInsets bo_pointInsideExtension;

/*
 只有在首次和size发生变化才调用该方法
 super什么也没做，若清楚该方法的机制，重写该方法是可选择不调用super也可
 */
- (void)bo_layoutSubviewsOnlySizeChange:(CGSize)currSize
                                subInfo:(nullable NSDictionary *)subInfo;

//@property (nonatomic) NSValue *bo_fixIntrinsicContentSize;

@property (nonatomic, nullable) NSNumber * (^bo_pointInsideJudge)(CGRect rect,
                                                                  CGPoint point,
                                                                  UIEvent *event);

@property (nonatomic, nullable) UIView * _Nullable (^bo_hitTestHook)(UIView *sfView,
                                                                     CGPoint point,
                                                                     UIEvent * _Nullable event,
                                                                     UIView * _Nullable (^originImp)(CGPoint point,
                                                                                                     UIEvent * _Nullable event));

@end


@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (BOExtension)

- (nullable NSArray *)bo_arrayForKey:(KeyType)key;

- (nullable NSDictionary *)bo_dictionaryForKey:(KeyType)key;
- (nullable NSMutableDictionary *)bo_mutableDictionaryForKey:(KeyType)key;

- (nullable NSString *)bo_stringForKey:(KeyType)key;

- (nullable NSNumber *)bo_numberForKey:(KeyType)key;

- (BOOL)bo_boolValueForKey:(KeyType)key;

- (NSInteger)bo_integerValueForKey:(KeyType)key;

//注意：如果本身是double数值，用bo_floatValueForKey取的话会因为读取方式错误返回不一样数值哦，两个方法不可混用
- (float)bo_floatValueForKey:(KeyType)key;
- (double)bo_doubleValueForKey:(KeyType)key;

- (nullable NSValue *)bo_nsValueForKey:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
