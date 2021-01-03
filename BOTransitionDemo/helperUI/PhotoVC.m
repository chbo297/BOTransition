//
//  PhotoVC.m
//  CCTransitionOCDemo
//
//  Created by bo on 02/03/2018.
//  Copyright © 2018 CC. All rights reserved.
//

#import "PhotoVC.h"

@interface PhotoVC () <BOTransitionEffectControl>

@property (nonatomic, strong) UIButton *closeBtn;

@end

@implementation PhotoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.addSubview(self.imageV);
    self.imageV.image = [UIImage imageNamed:@"demophoto"];
    self.imageV.mas_makeConstraints(^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    });
    
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
    
    self.closeBtn.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.closeBtn.alpha <= 0.1) {
        [UIView animateWithDuration:0.2 animations:^{
            self.closeBtn.alpha = 1;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.closeBtn.alpha = 0;
}

- (BOOL)prefersStatusBarHidden {
    if (self.presentingViewController) {
        return self.presentingViewController.prefersStatusBarHidden;
    }
    return YES;
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
    }
    return _imageV;
}

#pragma mark - BOTransition

- (void)bo_transitioning:(BOTransitioning *)transitioning prepareForStep:(BOTransitionStep)step transitionInfo:(BOTransitionInfo)transitionInfo elements:(NSMutableArray<BOTransitionElement *> *)elements {
    
    __block BOTransitionElement *photoele;
    [elements enumerateObjectsUsingBlock:^(BOTransitionElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (BOTransitionElementTypePhotoMirror == obj.elementType) {
            photoele = obj;
        }
    }];
    
    if (!photoele) {
        return;
    }
    
    if (BOTransitionActMoveIn == transitioning.transitionAct) {
        //这个时候当前View还没有布局，可以选择layoutIfNeeded、或者直接赋予frame都行
//        [self.view layoutIfNeeded];
        photoele.toView = self.imageV;
        photoele.toFrameCoordinateInVC = @(self.view.bounds);
    } else {
        photoele.fromView = self.imageV;
    }
}

@end
