//
//  ContentVC.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/4.
//

#import "ContentVC.h"

@interface ContentVC ()

@property (nonatomic, strong) UIButton *closeBtn;

@end

@implementation ContentVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.8 green:0.68 blue:0.68 alpha:1];
    
    UILabel *lb = [UILabel new];
    lb.text = @"Content";
    lb.font = [UIFont systemFontOfSize:30];
    [self.view addSubview:lb];
    [lb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
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
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = UIButton.cc_button(UIButtonTypeSystem);
        _closeBtn.cc_setBgImage([UIImage imageNamed:@"white_close"]);
    }
    return _closeBtn;
}

@end
