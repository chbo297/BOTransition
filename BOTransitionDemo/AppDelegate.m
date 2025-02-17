//
//  AppDelegate.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/2.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

//- (void)testCheckVelPinch {
//    NSInteger pcount = self.pinchInfoAr.count;
//    if (pcount <= 1) {
//        NSLog(@"~~~p0.1: 0pt/s");
//        NSLog(@"~~~p0.2: 0pt/s");
//        return;
//    }
//    CGFloat lastspace = self.pinchInfoAr.lastObject.space;
//    CGFloat lastts = self.pinchInfoAr.lastObject.ts;
//    NSNumber *sp01 = nil;
//    NSNumber *sp02 = nil;
//    for (NSInteger idx = self.pinchInfoAr.count - 2; idx >= 0; idx--) {
//        BOTransitionGesturePinchInfo *infoitem = self.pinchInfoAr[idx];
//        CGFloat durts = lastts - infoitem.ts;
//        if (nil == sp01) {
//            if (durts >= 0.1) {
//                sp01 = @((lastspace - infoitem.space) / durts);
//            }
//        }
//        if (nil == sp02) {
//            if (durts >= 0.2) {
//                sp02 = @((lastspace - infoitem.space) / durts);
//            }
//        }
//        
//        if (pcount >= sf_max_pinchInfo_count
//            && idx == 1) {
//            //到最大后，取第二个就好了，因为前面可能被裁剪过数据
//            break;
//        } else if (idx == 0) {
//            sp01 = @((lastspace - infoitem.space) / durts);
//            sp02 = sp01;
//        }
//    }
//    
//    NSLog(@"~~~p0.1: %@pt/s", sp01);
//    NSLog(@"~~~p0.2: %@pt/s", sp02);
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
