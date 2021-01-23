//
//  ListVC.m
//  BOTransitionDemo
//
//  Created by bo on 2021/1/15.
//

#import "ListVC.h"
#import "DemoCollectionViewCell.h"

static CGSize sf_cell_size;

@interface ListVC () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, BOTransitionEffectControl>

@property (nonatomic, strong) NSArray *dataAr;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, weak) UIView *currTargetView;

@end

@implementation ListVC

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
    sf_cell_size = CGSizeMake(self.view.bounds.size.width, 167);
    
    NSMutableArray<NSDictionary *> *muar = [NSMutableArray new];
    for (NSInteger idx = 0; idx < 40; idx++) {
        [muar addObject:@{
            @"title": [NSString stringWithFormat:@"listcell%@", @(idx).description],
        }];
    }
    self.dataAr = @[
        @{
            @"title": @"ListPage",
            @"dataAr": muar
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

#pragma mark - collection view delegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(CGRectGetWidth(collectionView.bounds), 167);
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

@end
