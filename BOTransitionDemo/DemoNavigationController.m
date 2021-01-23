//
//  DemoNavigationController.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/3.
//

#import "DemoNavigationController.h"
#import "BODisplayTouchPoint.h"

@interface DemoNavigationController ()

@end

@implementation DemoNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    [self bo_setTransProxy:YES];
    
    /*
     如果需要设置当前NavigationController的Delegate，请不要直接设置self.delegate，
     delegate被BOTransitionNCProxy占用了，可以通过navigationControllerDelegate设置,
     BOTransitionNCProxy会进行消息转发
     */
//    self.bo_transProxy.navigationControllerDelegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [BODisplayTouchPoint addToView:self.view.window];
}

@end
