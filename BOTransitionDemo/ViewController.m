//
//  ViewController.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/2.
//

#import "ViewController.h"
#import "DemoCollectionViewCell.h"
#import "PopCardVC.h"
#import "PhotoVC.h"
#import "PopCardVC.h"
#import "AvatarDetailVC.h"
#import "BOTransition.h"
#import "ContentVC.h"
#import "ListVC.h"
#import "InnerNC.h"

static CGSize sf_cell_size;

@interface ViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, BOTransitionEffectControl>

@property (nonatomic, strong) NSArray *dataAr;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, weak) UIView *currTargetView;

@end

@implementation ViewController

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                             collectionViewLayout:[UICollectionViewFlowLayout new]];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.alwaysBounceVertical = YES;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_collectionView registerClass:[DemoCollectionViewCell class] forCellWithReuseIdentifier:@"ds"];
        [_collectionView registerClass:[DemoHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"dh"];
        
    }
    return _collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sf_cell_size = CGSizeMake(108, 135);
    __weak typeof(self) ws = self;
    self.dataAr = @[
        @{
            @"title": @"UINavigation-push",
            @"dataAr": @[
                    @{
                        @"title": @"avatar effect",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            cell.imageV.layer.cornerRadius = 54;
                            cell.imageV.layer.masksToBounds = YES;
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            AvatarDetailVC *vc = [AvatarDetailVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig configWithEffect:BOTransitionEffectElementExpensionOnlyEle
                                                       startView:cell.imageV];
                            [ws.navigationController pushViewController:vc animated:YES];
                            
                            /*
                             也可以通过以下方式详细设置需要的效果：
                             [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                 
                                 NSDictionary *effectinfo = @{
                                     @"style": @"ElementExpension",
                                     @"config": @{
                                             @"pinGes": @(YES),
                                             @"zoomContentMode": @(UIViewContentModeScaleAspectFill),
                                     },
                                     
                                     @"configBlock": ^(BOTransitionConfig *config) {
                                         config.moveOutSeriousGesDirection = 0;
                                     },
                                     @"gesTriggerDirection": @(UISwipeGestureRecognizerDirectionDown),
                                 };
                                 
                                 config.startViewFromBaseVC = cell.imageV;
                             }];
                             */
                        }
                    },
                    
                    @{
                        @"title": @"photo",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            cell.imageV.image = [UIImage imageNamed:@"demophoto"];
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            PhotoVC *vc = [PhotoVC new];
                            ws.currTargetView = cell.imageV;
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig configWithEffect:BOTransitionEffectPhotoPreviewPinGes];
                            [ws.navigationController pushViewController:vc animated:YES];
                        }
                    },
                    
                    @{
                        @"title": @"plain",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            ContentVC *vc = [ContentVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                config.transitionEffect = BOTransitionEffectElementExpension;
                                config.startViewFromBaseVC = cell.imageV;
                            }];
                            [ws.navigationController pushViewController:vc animated:YES];
                        }
                    },
                    
                    @{
                        @"title": @"Scroll Vertical",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            ListVC *vc = [ListVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                config.transitionEffect = BOTransitionEffectMovingBottom;
                            }];
                            [ws.navigationController pushViewController:vc animated:YES];
                        }
                    },
                    
                    @{
                        @"title": @"Push Right",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            ListVC *vc = [ListVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                config.transitionEffect = BOTransitionEffectMovingRight;
                            }];
                            [ws.navigationController pushViewController:vc animated:YES];
                        }
                    },
                    
//                    @{
//                        @"title": @"Inner NC",
//                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
//                            
//                        },
//                        @"block": ^(DemoCollectionViewCell *cell){
//                            InnerNC *vc = [InnerNC new];
////                            vc.bo_transitionConfig =\
////                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
////                                config.transitionEffect = BOTransitionEffectMovingRight;
////                            }];
//                            [ws.navigationController pushViewController:vc animated:YES];
//                        }
//                    },
            ]
        },
        
        @{
            @"title": @"Present",
            @"dataAr": @[
                    @{
                        @"title": @"pop card",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            cell.imageV.image = nil;
                            cell.imageV.backgroundColor = [UIColor colorWithRed:0.8 green:0.68 blue:0.68 alpha:1];
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            PopCardVC *vc = [PopCardVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig configWithEffect:BOTransitionEffectPopCard
                                                       startView:cell];
                            [ws presentViewController:vc animated:YES completion:nil];
                        }
                    },
                    
                    @{
                        @"title": @"avatar effect",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            cell.imageV.layer.cornerRadius = 54;
                            cell.imageV.layer.masksToBounds = YES;
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            AvatarDetailVC *vc = [AvatarDetailVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig configWithEffect:BOTransitionEffectElementExpensionOnlyEle
                                                       startView:cell.imageV];
                            [ws presentViewController:vc animated:YES completion:nil];
                        }
                    },
                    
                    @{
                        @"title": @"photo",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            cell.imageV.image = [UIImage imageNamed:@"demophoto"];
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            PhotoVC *vc = [PhotoVC new];
                            ws.currTargetView = cell.imageV;
                            ws.definesPresentationContext = YES;
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                config.transitionEffect = BOTransitionEffectPhotoPreviewPinGes;
                                config.presentOverTheContext = YES;
                            }];
                            vc.bo_transitionConfig.presentOverTheContext = YES;
                            [ws presentViewController:vc animated:YES completion:nil];
                        }
                    },
                    
                    @{
                        @"title": @"plain",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            ContentVC *vc = [ContentVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                config.transitionEffect = BOTransitionEffectElementExpension;
                                config.startViewFromBaseVC = cell.imageV;
                            }];
                            [ws presentViewController:vc animated:YES completion:nil];
                        }
                    },
                    
                    @{
                        @"title": @"Scroll Vertical",
                        @"cellSetupBlock": ^(DemoCollectionViewCell *cell){
                            
                        },
                        @"block": ^(DemoCollectionViewCell *cell){
                            ListVC *vc = [ListVC new];
                            vc.bo_transitionConfig =\
                            [BOTransitionConfig makeConfig:^(BOTransitionConfig * _Nonnull config) {
                                config.transitionEffect = BOTransitionEffectMovingBottom;
                            }];
                            [ws presentViewController:vc animated:YES completion:nil];
                        }
                    },
            ]
        }
    ];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.top.equalTo(self.view.mas_top);
            make.bottom.equalTo(self.view.mas_bottom);
        }
        make.leading.trailing.equalTo(self.view);
    }];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}


#pragma mark - collection view delegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    CGFloat w = (CGRectGetWidth(collectionView.bounds) - 2.f * sf_cell_size.width) / 3.f;
    return w;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 25;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat w = (CGRectGetWidth(collectionView.bounds) - 2.f * sf_cell_size.width) / 3.f;
    return UIEdgeInsetsMake(0, w, 40, w);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return sf_cell_size;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    DemoHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                            withReuseIdentifier:@"dh"
                                                                   forIndexPath:indexPath];
    NSDictionary *datadic = self.dataAr[indexPath.section];
    header.label.text = datadic[@"title"];
    return header;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(CGRectGetWidth(collectionView.bounds), 40);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.dataAr.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.dataAr[section] objectForKey:@"dataAr"] count];
}

- (NSDictionary *)dataDicFor:(NSIndexPath *)indexPath {
    return self.dataAr[indexPath.section][@"dataAr"][indexPath.row];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DemoCollectionViewCell *cell =\
    [collectionView dequeueReusableCellWithReuseIdentifier:@"ds" forIndexPath:indexPath];
    cell.imageV.image = [UIImage imageNamed:@"testImg"];
    NSDictionary *datadic = [self dataDicFor:indexPath];
    NSString *title = [datadic objectForKey:@"title"];
    cell.label.text = title;
    void (^cellbk)(DemoCollectionViewCell *cell) = [datadic objectForKey:@"cellSetupBlock"];
    if (cellbk) {
        cellbk(cell);
    }
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    DemoCollectionViewCell *cell = (id)[collectionView cellForItemAtIndexPath:indexPath];
    if (![cell isKindOfClass:[DemoCollectionViewCell class]]) {
        cell = nil;
    }
    NSDictionary *datadic = [self dataDicFor:indexPath];
    void (^bk)(DemoCollectionViewCell *cell) = [datadic objectForKey:@"block"];
    if (bk) {
        bk(cell);
    }
    
    return NO;
}

#pragma mark - BOTransition

- (void)bo_transitioning:(BOTransitioning *)transitioning prepareForStep:(BOTransitionStep)step transitionInfo:(BOTransitionInfo)transitionInfo elements:(NSMutableArray<BOTransitionElement *> *)elements {
    if (BOTransitionStepInstallElements != step) {
        return;
    }
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
        photoele.fromView = self.currTargetView;
    } else {
        photoele.toView = self.currTargetView;
    }
}

@end
