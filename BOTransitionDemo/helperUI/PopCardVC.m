//
//  PopCardVC.m
//  CCTransitionOCDemo
//
//  Created by bo on 02/03/2018.
//  Copyright © 2018 CC. All rights reserved.
//

#import "PopCardVC.h"
#import "BOTransition.h"
@interface PopCardVC ()

@property (strong, nonatomic) UIView *board;

@property (nonatomic, strong) UIButton *closeBtn;

@end

@implementation PopCardVC


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
//        [self cc_setCCPresentTransitionView:nil from:nil to:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.27];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.view.addSubview(self.board);
    self.view.addSubview(self.closeBtn);
    
    self.closeBtn.mas_makeConstraints(^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.board.mas_trailing).offset(-4);
        make.centerY.equalTo(self.board.mas_top).offset(4);
    });
    
    self.board.mas_makeConstraints(^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(self.view).offset(-40).priorityHigh();
        make.height.equalTo(self.view).multipliedBy(2.f/3.f);
    });
    self.board.backgroundColor = [UIColor whiteColor];
    self.board.layer.cornerRadius = 16;
    
    __weak typeof(self) ws = self;
    self.closeBtn.cc_setTouchUpInSideDo(^(UIButton *bt) {
        if (ws.presentingViewController) {
            [ws.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else if (ws.navigationController) {
            [ws.navigationController popViewControllerAnimated:YES];
        }
    });
}


- (UIView *)board {
    if (!_board) {
        _board = [UIView new];
        
    }
    return _board;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = UIButton.cc_button(UIButtonTypeSystem);
        _closeBtn.cc_setBgImage([UIImage imageNamed:@"white_close"]);
    }
    return _closeBtn;
}

@end
