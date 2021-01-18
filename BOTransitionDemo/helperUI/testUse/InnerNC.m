//
//  InnerNC.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/15.
//

#import "InnerNC.h"
#import "ContentVC.h"

@interface InnerNC () <BOTransitionConfigDelegate>

@property (nonatomic, strong) UINavigationController *nc;
@property (nonatomic, strong) BOTransitionNCProxy *ncProxy;

@end

@implementation InnerNC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    // Do any additional setup after loading the view.
    _ncProxy = [BOTransitionNCProxy transitionProxyWithNC:self.nc];
    
    [self.view addSubview:self.nc.view];
    [self addChildViewController:self.nc];
    [self.nc didMoveToParentViewController:self];
    
    ContentVC *vc = [ContentVC new];
//    vc.bo_transitionConfig =\
//    [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
//        config.transitionEffect = BOTransitionEffectMovingRight;
//    }];
    [self.nc pushViewController:vc animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ContentVC *vc2 = [ContentVC new];
    //    vc.bo_transitionConfig =\
    //    [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
    //        config.transitionEffect = BOTransitionEffectMovingRight;
    //    }];
        [self.nc pushViewController:vc2 animated:YES];
    });
}

- (UINavigationController *)nc {
    if (!_nc) {
        UIViewController *rvc = [UIViewController new];
        rvc.view.backgroundColor = [UIColor lightGrayColor];
        _nc = [[UINavigationController alloc] initWithRootViewController:rvc];
    }
    return _nc;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSNumber *)bo_trans_shouldRecTransitionGes:(UIGestureRecognizer *)gesture transitionType:(BOTransitionType)transitionType subInfo:(NSDictionary *)subInfo {
    if (BOTransitionTypeNavigation == transitionType) {
        UINavigationController *nc = [subInfo objectForKey:@"nc"];
        BOOL popinner = self.nc.viewControllers.count > 2;
        if (nc == self.nc) {
            return @(popinner);
        } else {
            return @(!popinner);
        }
    }
    
    return nil;
}

@end
