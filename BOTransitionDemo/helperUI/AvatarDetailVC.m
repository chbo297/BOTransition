//
//  AvatarDetailVC.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/3.
//

#import "AvatarDetailVC.h"

@interface AvatarDetailVC ()

@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIImageView *imageV;

@end

@implementation AvatarDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    self.view.addSubview(self.closeBtn);
    self.closeBtn.mas_makeConstraints(^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
        } else {
            make.top.equalTo(self.view.mas_top).offset(44);
        }
        make.leading.equalTo(self.view).offset(20);
    });
    
    __weak typeof(self) ws = self;
    self.closeBtn.cc_setTouchUpInSideDo(^(UIButton *bt) {
        if (ws.presentingViewController) {
            [ws.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else if (ws.navigationController) {
            [ws.navigationController popViewControllerAnimated:YES];
        }
    });
    
    self.view.addSubview(self.imageV);
    self.imageV.image = [UIImage imageNamed:@"testImg"];
    CGFloat w = 112;
    self.imageV.mas_makeConstraints(^(MASConstraintMaker *make) {
        make.top.equalTo(self.closeBtn).offset(0);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(w, w));
    });
    self.imageV.layer.cornerRadius = w / 2.f;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = UIButton.cc_button(UIButtonTypeSystem);
        _closeBtn.cc_setBgImage([UIImage imageNamed:@"white_close"]);
    }
    return _closeBtn;
}

- (UIImageView *)imageV {
    if (!_imageV) {
        _imageV = [UIImageView new];
        _imageV.contentMode = UIViewContentModeScaleAspectFit;
        _imageV.clipsToBounds = YES;
    }
    return _imageV;
}

#pragma mark - BOTransition

- (void)bo_transitioning:(BOTransitioning *)transitioning prepareForStep:(BOTransitionStep)step transitionInfo:(BOTransitionInfo)transitionInfo elements:(NSMutableArray<BOTransitionElement *> *)elements {
    if (step != BOTransitionStepAfterInstallElements) {
        return;
    }
    __block BOTransitionElement *ele;
    [elements enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (BOTransitionElementTypeNormal == obj.elementType) {
            ele = obj;
        }
    }];
    
    if (!ele
        || !ele.transitionView
        || !ele.transitionView.superview) {
        return;
    }
    ele.transitionView.alpha = 1;
    ele.alphaAllow = NO;
    if (BOTransitionActMoveIn == transitioning.transitionAct) {
        //这个时候当前View还没有布局，可以选择layoutIfNeeded、或者直接赋予frame都行
        [self.view layoutIfNeeded];
        ele.toView = self.imageV;
        ele.frameTo = [self.imageV convertRect:self.imageV.bounds
                                        toView:ele.transitionView.superview];
    } else {
        ele.fromView = self.imageV;
        ele.frameFrom = [self.imageV convertRect:self.imageV.bounds
                                          toView:ele.transitionView.superview];
    }
}

@end
