//
//  PDLoopScrollView.m
//  PipeDog
//
//  Created by liang on 2018/11/30.
//  Copyright © 2017年 PipeDog. All rights reserved.
//

#import "PDLoopScrollView.h"

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
    weakTimer->_timer = [NSTimer timerWithTimeInterval:interval target:weakTimer selector:@selector(tick:) userInfo:nil repeats:repeats];
    [[NSRunLoop mainRunLoop] addTimer:weakTimer->_timer forMode:NSRunLoopCommonModes];
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

@interface PDLoopScrollView () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) _PDWeakTimer *timer;
@property (nonatomic, assign, readonly) CGFloat unitLen;
@property (nonatomic, assign, readonly) CGFloat curOffsetLen;
@property (nonatomic, assign, readonly) CGFloat contentLen;
@property (nonatomic, assign) CGFloat preOffsetLen;
@property (nonatomic, strong) UIView<PDLoopScrollViewPageControl> *defaultPageControl; // Not displayed on the interface, just for logic.
@property (nonatomic, strong, readonly) UIView<PDLoopScrollViewPageControl> *realPageControl;

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
        [self commitInit];
        [self createViewHierarchy];
        [self layoutContentViews];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
        [self commitInit];
        [self createViewHierarchy];
        [self layoutContentViews];
    }
	return self;
}

- (void)commitInit {
    self.userInteractionEnabled = YES;
    self.scrollEnabled = YES;
    self.secs = 0.0;
    self.scrollDirection = PDLoopScrollViewDirectionHorizontal;
}

- (void)createViewHierarchy {
    [self addSubview:self.collectionView];
}

- (void)layoutContentViews {
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.collectionView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.collectionView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];
}

#pragma mark - Public Methods
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    [self invalidate];
    
    _currentIndex = index; // Do not call setter methods of `currentIndex`.
    self.realPageControl.currentPage = index;
    
    if (!animated && [self.delegate respondsToSelector:@selector(scrollView:didScrollToIndex:)]) {
        [self.delegate scrollView:self didScrollToIndex:_currentIndex];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
    
    [self fire];
}

- (void)reloadData {
    self.numberOfItems = [self.dataSource numberOfItemsInScrollView:self];
    
    self.realPageControl.numberOfPages = self.numberOfItems;
    [self.collectionView reloadData];

    [self fire];
}

#pragma mark - Private Methods
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
    // Reason: The system will remove all CoreAnimation animations in the view not-on-screen, so that the animation cannot be completed and the rotations stay in the state of switching.
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

- (NSInteger)convertIndexWithIndexPath:(NSIndexPath *)indexPath {
    if (!self.numberOfItems) {
        return 0;
    }
    if (indexPath.row >= self.numberOfItems) {
        return 0;
    }
    return indexPath.item;
}

#pragma mark - UICollectionView Protocols
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.numberOfItems == 1) {
        return 1;
    }
    return self.numberOfItems + 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return self.collectionView.frame.size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reuseId" forIndexPath:indexPath];
    
    for (UIView *subview in [cell.contentView.subviews copy]) {
        [subview removeFromSuperview];
    }

    NSInteger index = [self convertIndexWithIndexPath:indexPath];
    UIView *view = [self.dataSource scrollView:self cellForItemAtIndex:index];
    
    if (view) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:view];
        
        [NSLayoutConstraint activateConstraints:@[
            [view.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [view.leftAnchor constraintEqualToAnchor:cell.contentView.leftAnchor],
            [view.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
            [view.rightAnchor constraintEqualToAnchor:cell.contentView.rightAnchor],
        ]];
    }
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(scrollView:didSelectItemAtIndex:)]) {
        NSInteger index = self.realPageControl.currentPage;
        [self.delegate scrollView:self didSelectItemAtIndex:index];
    }
}

#pragma mark - UIScrollView Protocols
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self fire];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UICollectionView *collectionView = (UICollectionView *)scrollView;
    if (self.preOffsetLen > self.curOffsetLen) {
        if (self.curOffsetLen < 0) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.numberOfItems inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    } else {
        if (self.curOffsetLen > self.contentLen - self.unitLen) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    }
    
    if (round(self.curOffsetLen / self.unitLen) >= self.realPageControl.numberOfPages) {
        self.currentIndex = 0;
    } else {
        self.currentIndex = self.curOffsetLen / self.unitLen;
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
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.userInteractionEnabled = YES;
        _collectionView.contentInset = UIEdgeInsetsZero;
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"reuseId"];
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

- (CGFloat)unitLen {
    return self.scrollDirection == PDLoopScrollViewDirectionHorizontal ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
}

- (CGFloat)curOffsetLen {
    return self.scrollDirection == PDLoopScrollViewDirectionHorizontal ? self.collectionView.contentOffset.x : self.collectionView.contentOffset.y;
}

- (CGFloat)contentLen {
    return self.scrollDirection == PDLoopScrollViewDirectionHorizontal ? self.collectionView.contentSize.width : self.collectionView.contentSize.height;
}

- (UIView<PDLoopScrollViewPageControl> *)defaultPageControl {
    if (!_defaultPageControl) {
        _defaultPageControl = (UIView<PDLoopScrollViewPageControl> *)[[UIPageControl alloc] init];
    }
    return _defaultPageControl;
}

- (UIView<PDLoopScrollViewPageControl> *)realPageControl {
    if (self.pageControl) {
        return self.pageControl;
    }
    return self.defaultPageControl;
}

#pragma mark - Setter Methods
- (void)setDataSource:(id<PDLoopScrollViewDataSource>)dataSource {
    _dataSource = dataSource;
    
    NSAssert([_dataSource respondsToSelector:@selector(numberOfItemsInScrollView:)], @"Method [- numberOfItemsInScrollView:] must be impl.");
    NSAssert([_dataSource respondsToSelector:@selector(scrollView:cellForItemAtIndex:)], @"Method [- scrollView:cellForItemAtIndex:] must be impl.");
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

- (void)setCurrentIndex:(NSInteger)currentIndex {
    if (_currentIndex == currentIndex) {
        return;
    }
    _currentIndex = currentIndex;
    self.realPageControl.currentPage = _currentIndex;
    
    if ([self.delegate respondsToSelector:@selector(scrollView:didScrollToIndex:)]) {
        [self.delegate scrollView:self didScrollToIndex:_currentIndex];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.collectionView.backgroundColor = backgroundColor;
}

@end
