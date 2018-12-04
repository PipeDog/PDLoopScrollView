//
//  PDLoopScrollView.m
//  PipeDog
//
//  Created by liang on 2018/11/30.
//  Copyright © 2017年 PipeDog. All rights reserved.
//

#import "PDLoopScrollView.h"
#import <Masonry/Masonry.h>

@interface _PDWeakTimer : NSObject {
@private
    NSTimer *_timer;
    void (^_block)(void);
}

+ (_PDWeakTimer *)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(void))block;

- (void)fire;
- (void)invalidate;

@end

@implementation _PDWeakTimer

- (void)dealloc {
    [self invalidate];
}

+ (_PDWeakTimer *)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(void))block {
    _PDWeakTimer *weakTimer = [[_PDWeakTimer alloc] init];
    weakTimer->_block = [block copy];
    weakTimer->_timer = [NSTimer timerWithTimeInterval:interval target:weakTimer selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:weakTimer->_timer forMode:NSRunLoopCommonModes];
    return weakTimer;
}

- (void)tick:(NSTimer *)sender {
    !_block ?: _block();
}

- (void)fire {
    [_timer fire];
    !_block ?: _block();
}

- (void)invalidate {
    [_timer invalidate];
    _timer = nil;
}

@end

@implementation PDLoopScrollViewPageControlConfiguration

@end

@interface PDLoopScrollView () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *viewModels;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) _PDWeakTimer *timer;
@property (nonatomic, assign, readonly) CGFloat unitLen;
@property (nonatomic, assign, readonly) CGFloat curOffsetLen;
@property (nonatomic, assign, readonly) CGFloat contentLen;
@property (nonatomic, assign) CGFloat preOffsetLen;
@property (nonatomic, strong) PDLoopScrollViewPageControlConfiguration *pageControlConfiguration;

@end

@implementation PDLoopScrollView

- (void)dealloc {
    [self invalidate];
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
        [self makeDefault];
		[self makeConstraints];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
        [self makeDefault];
		[self makeConstraints];
	}
	return self;
}

#pragma mark - Public Methods
- (void)reloadData {
    NSArray *viewModels = [self.delegate viewModelsForScrollView:self];
    
    self.viewModels = [NSArray arrayWithArray:viewModels];
    self.pageControl.numberOfPages = self.viewModels.count;
    [self.collectionView reloadData];

    [self makePageControlConfig];
    [self fire];
}

- (void)configPageControl:(void (^)(PDLoopScrollViewPageControlConfiguration * _Nonnull))block {
    PDLoopScrollViewPageControlConfiguration *configuration = [[PDLoopScrollViewPageControlConfiguration alloc] init];
    !block ?: block(self.pageControlConfiguration = configuration);
    
    [self makePageControlConfig];
}

#pragma mark - Private Methods
- (void)makeDefault {
    self.userInteractionEnabled = YES;
    self.scrollEnabled = YES;
    self.secs = 0.0;
    self.scrollDirection = PDLoopScrollViewDirectionHorizontal;
}

- (void)makeConstraints {
	[self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.left.bottom.and.right.equalTo(self);
	}];
	
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(25);
        make.bottom.equalTo(self);
        make.centerX.equalTo(self);
    }];
}

- (void)makePageControlConfig {
    PDLoopScrollViewPageControlConfiguration *configuration = self.pageControlConfiguration;
    if (!configuration) { return; }
    
    if (!CGRectEqualToRect(configuration.frame, CGRectZero)) {
        [self.pageControl mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(configuration.frame.origin.y);
            make.left.mas_equalTo(configuration.frame.origin.x);
            make.size.mas_equalTo(configuration.frame.size);
        }];
    }
    
    self.pageControl.hidden = configuration.hidden;
    
    if (configuration.currentPageIndicatorTintColor) {
        self.pageControl.currentPageIndicatorTintColor = configuration.currentPageIndicatorTintColor;
    }
    if (configuration.pageIndicatorTintColor) {
        self.pageControl.pageIndicatorTintColor = configuration.pageIndicatorTintColor;
    }
}

- (void)turnPage {
    CGFloat newOffsetLen = self.curOffsetLen + self.unitLen;
    
    if (newOffsetLen == self.contentLen - self.unitLen) {
        // Last page, scroll to first page.
        newOffsetLen += 1;
    }
    
    CGPoint offset;
    if (self.scrollDirection == PDLoopScrollViewDirectionHorizontal) {
        offset = CGPointMake(newOffsetLen, 0);
    } else {
        offset = CGPointMake(0, newOffsetLen);
    }
    [self.collectionView setContentOffset:offset animated:YES];
    
    // Fix: Switch TabBar or Navigation Push Error.
    // Reason: The system will remove all coreAnimation animations in the view not-on-screen, so that the animation cannot be completed and the rotations stay in the state of switching.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.curOffsetLen != newOffsetLen && self.curOffsetLen != 0) {
            self.collectionView.contentOffset = offset;
        }
    });
}

- (void)fire {
    [self invalidate];
    
    if (self.secs == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.timer = [_PDWeakTimer timerWithTimeInterval:self.secs repeats:YES block:^{
        [weakSelf turnPage];
    }];
}

- (void)invalidate {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (id)viewModelForIndexPath:(NSIndexPath *)indexPath {
    if (!self.viewModels.count) {
        return nil;
    }
    if (indexPath.row >= self.viewModels.count) {
        return self.viewModels.firstObject;
    }
    return self.viewModels[indexPath.row];
}

#pragma mark - UICollectionView Protocols
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.viewModels.count == 1) {
        return 1;
    }
    return self.viewModels.count + 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return self.collectionView.frame.size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reuseId" forIndexPath:indexPath];
    
    for (UIView *subview in [cell.subviews copy]) {
        [subview removeFromSuperview];
    }
    
    id viewModel = [self viewModelForIndexPath:indexPath];
    UIView *view = [self.delegate scrollView:self viewForViewModel:viewModel];
    
    if (view) {
        [cell addSubview:view];
        
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell);
        }];
    }
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(scrollView:didSelectItemOfViewModel:)]) {
        id viewModel = self.viewModels[self.pageControl.currentPage];
        [self.delegate scrollView:self didSelectItemOfViewModel:viewModel];
    }
}

#pragma mark - UIScrollView Protocols
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.pageControl.currentPage = self.curOffsetLen / self.unitLen;
    [self fire];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UICollectionView *collectionView = (UICollectionView *)scrollView;
    if (self.preOffsetLen > self.curOffsetLen) {
        if (self.curOffsetLen < 0) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.viewModels.count inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    } else {
        if (self.curOffsetLen > self.contentLen - self.unitLen) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    }
    
    if (round(self.curOffsetLen / self.unitLen) >= self.pageControl.numberOfPages) {
        self.pageControl.currentPage = 0;
    } else {
        self.pageControl.currentPage = self.curOffsetLen / self.unitLen;
    }
    self.preOffsetLen = self.curOffsetLen;
}

#pragma mark - Getter Methods
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"reuseId"];
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.userInteractionEnabled = YES;
        _collectionView.contentInset = UIEdgeInsetsZero;
        [self addSubview:_collectionView];
    }
    return _collectionView;
}

- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.minimumLineSpacing = 0;
        _flowLayout.itemSize = self.frame.size;
    }
    return _flowLayout;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPage = 0;
        _pageControl.numberOfPages = self.viewModels.count;
        _pageControl.backgroundColor = [UIColor clearColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        _pageControl.hidesForSinglePage = YES;
        [self addSubview:_pageControl];
    }
    return _pageControl;
}

- (CGFloat)unitLen {
    return self.scrollDirection == PDLoopScrollViewDirectionHorizontal ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
}

- (CGFloat)curOffsetLen {
    return self.scrollDirection == PDLoopScrollViewDirectionHorizontal ? self.collectionView.contentOffset.x : self.collectionView.contentOffset.y;
}

- (CGFloat)contentLen {
    return self.scrollDirection == PDLoopScrollViewDirectionHorizontal ? self.collectionView.contentSize.width : self.collectionView.contentSize.height;
}

#pragma mark - Setter Methods
- (void)setDelegate:(id<PDLoopScrollViewDelegate>)delegate {
    _delegate = delegate;

    NSAssert([_delegate respondsToSelector:@selector(scrollView:viewForViewModel:)], @"Method [- scrollView:viewForViewModel:] must be impl");
    NSAssert([_delegate respondsToSelector:@selector(viewModelsForScrollView:)], @"Method [- viewModelsForScrollView:] must be impl");
}

- (void)setScrollDirection:(PDLoopScrollViewDirection)scrollDirection {
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        if (scrollDirection == PDLoopScrollViewDirectionVertical) {
            self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        } else {
            self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
        [self.collectionView reloadData];
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    self.collectionView.scrollEnabled = _scrollEnabled;
}

@end
