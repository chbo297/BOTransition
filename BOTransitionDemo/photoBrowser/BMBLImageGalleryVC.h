//
//  BOImageBrowserVC.h
//  BOTransitionDemo
//
//  Created by bo on 2025/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BOImageBrowserVC : UIViewController

/*
 {
 "image": [UIImage],
 "imageUrl": "",  url string
 }
 */
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *dataAr;

@property (nonatomic, assign) NSInteger currIdx;

@end

NS_ASSUME_NONNULL_END
