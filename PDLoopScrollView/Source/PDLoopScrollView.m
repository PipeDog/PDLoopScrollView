//
//  PDLoopScrollView.m
//  PipeDog
//
//  Created by liang on 2018/11/30.
//  Copyright © 2017年 PipeDog. All rights reserved.
//

#import "PDLoopScrollView.h"

typedef NS_OPTIONS(NSUInteger, PDSwitchIndexActionOptions) {
    PDSwitchIndexActionOptionSetProperty     = 1 << 0,
    PDSwitchIndexActionOptionSetPageControl  = 1 << 1,
    PDSwitchIndexActionOptionInvokeDelegate  = 1 << 2,
    PDSwitchIndexActionOptionAll             = 0xFFF,
};

@class PDSwitchIndexTransaction;

@protocol PDSwitchIndexTransactionDelegate <NSObject>

- (void)didFinishExecutingTransaction:(PDSwitchIndexTransaction *)transaction;

@end

@interface PDSwitchIndexTransaction : NSObject

@property (nonatomic, assign, readonly) NSInteger pageControlIndex;
@property (nonatomic, assign, getter=isExecuting, readonly) BOOL executing;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                           pageControl:(UIView<PDLoopScrollViewPageControl> *)pageControl
                    defaultPageControl:(UIView<PDLoopScrollViewPageControl> *)defaultPageControl
                       scrollDirection:(PDLoopScrollViewDirection)scrollDirection
                         numberOfItems:(NSInteger)numberOfItems
                              newIndex:(NSInteger)newIndex
                              animated:(BOOL)animated
                               unitLen:(CGFloat)unitLen;

- (void)addDelegate:(id<PDSwitchIndexTransactionDelegate>)delegate;
- (void)removeDelegate:(id<PDSwitchIndexTransactionDelegate>)delegate;

- (void)commit;

@end

@implementation PDSwitchIndexTransaction {
    PDLoopScrollViewDirection _scrollDirection;
    NSInteger _numberOfItems, _newIndex;
    BOOL _animated;
    CGFloat _unitLen;
    
    __weak UICollectionView *_collectionView;
    __weak UIView<PDLoopScrollViewPageControl> *_pageControl;
    __weak UIView<PDLoopScrollViewPageControl> *_defaultPageControl;
    
    NSHashTable<id<PDSwitchIndexTransactionDelegate>> *_delegates;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                           pageControl:(UIView<PDLoopScrollViewPageControl> *)pageControl
                    defaultPageControl:(UIView<PDLoopScrollViewPageControl> *)defaultPageControl
                       scrollDirection:(PDLoopScrollViewDirection)scrollDirection
                         numberOfItems:(NSInteger)numberOfItems
                              newIndex:(NSInteger)newIndex
                              animated:(BOOL)animated
                               unitLen:(CGFloat)unitLen {
    self = [super init];
    if (self) {
        _collectionView = collectionView;
        _pageControl = pageControl;
        _defaultPageControl = defaultPageControl;
        _scrollDirection = scrollDirection;
        _numberOfItems = numberOfItems;
        _newIndex = newIndex;
        _animated = animated;
        _unitLen = unitLen;
        
        _executing = NO;
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)addDelegate:(id<PDSwitchIndexTransactionDelegate>)delegate {
    [_delegates addObject:delegate];
}

- (void)removeDelegate:(id<PDSwitchIndexTransactionDelegate>)delegate {
    [_delegates removeObject:delegate];
}

- (void)commit {
    NSInteger newIndex = _newIndex, numberOfItems = _numberOfItems;
    CGFloat unitLen = _unitLen;
    BOOL animated = _animated;
    UICollectionView *collectionView = _collectionView;
    
    // Get target contentOffset
    CGFloat newOffsetLen = newIndex * unitLen;
    if (newIndex >= numberOfItems) {
        // Last page, scroll to first page.
        newOffsetLen += 1;
    }
    
    CGPoint offset;
    if (_scrollDirection == PDLoopScrollViewDirectionHorizontal) {
        offset = CGPointMake(newOffsetLen, 0);
    } else {
        offset = CGPointMake(0, newOffsetLen);
    }
    
    // If the animation has already started, it can not be cancelled
    __weak typeof(self) weakSelf = self;
    [self performAnimation:^{
        self->_executing = YES;
        [collectionView setContentOffset:offset animated:animated];
    } completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        strongSelf->_executing = NO;
        strongSelf->_pageControlIndex = newIndex >= numberOfItems ? 0 : newIndex;
        [strongSelf notifyAllDelegates];
    }];
}

#pragma mark - Tool Methods
- (void)performAnimation:(void (^)(void))animation completion:(void (^)(void))completion {
    if (!_animated) {
        !animation ?: animation();
        !completion ?: completion();
        return;
    }
    
    !animation ?: animation();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !completion ?: completion();
    });
}

- (void)notifyAllDelegates {
    NSArray *allDelegates = self->_delegates.allObjects;
    
    for (id<PDSwitchIndexTransactionDelegate> delegate in allDelegates) {
        if ([delegate respondsToSelector:@selector(didFinishExecutingTransaction:)]) {
            [delegate didFinishExecutingTransaction:self];
        }
    }
}

@end

@interface PDSwitchIndexQueue : NSObject <PDSwitchIndexTransactionDelegate>

- (void)addTransaction:(PDSwitchIndexTransaction *)transaction;
- (void)removeAllTransactions;

@end

@implementation PDSwitchIndexQueue {
    NSMutableArray *_transactions;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _transactions = [NSMutableArray array];
    }
    return self;
}

- (void)addTransaction:(PDSwitchIndexTransaction *)transaction {
    [transaction addDelegate:self];
    [_transactions addObject:transaction];
    [self commitTransactionIfNeeded];
    
    if (_transactions.count <= 2) {
        return;
    }
    
    // queue                        : t0, t1, t2, t3, t4, t5, t6
    // after - t0 is executing      : t0, t6
    // after - t0 is not executing  : t6
    PDSwitchIndexTransaction *firstTransaction = _transactions[0];
    NSInteger startIndex = firstTransaction.isExecuting ? 1 : 0;
    NSInteger endIndex = _transactions.count - 1;
    NSRange range = NSMakeRange(startIndex, endIndex - startIndex);
    [_transactions removeObjectsInRange:range];
}

- (void)removeAllTransactions {
    NSArray<PDSwitchIndexTransaction *> *allTransactions = [_transactions copy];
    [_transactions removeAllObjects];
    
    for (PDSwitchIndexTransaction *transaction in allTransactions) {
        [transaction removeDelegate:self];
    }
}

#pragma mark - Tool Methods
- (void)commitTransactionIfNeeded {
    PDSwitchIndexTransaction *transaction = _transactions.firstObject;
    
    if (!transaction) {
        return;
    }
    if (transaction.isExecuting) {
        return;
    }
    
    [transaction commit];
}

#pragma mark - PDSwitchIndexTransactionDelegate
- (void)didFinishExecutingTransaction:(PDSwitchIndexTransaction *)transaction {
    [_transactions removeObject:transaction];
    [self commitTransactionIfNeeded];
}

@end

@interface PDWeakTimer : NSObject {
@private
    NSTimer *_timer;
    void (^_block)(void);
}

+ (PDWeakTimer *)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(void))block;

- (void)fire;
- (void)invalidate;

@end

@implementation PDWeakTimer

- (void)dealloc {
    [self invalidate];
}

+ (PDWeakTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                               repeats:(BOOL)repeats
                                 block:(void (^)(void))block {
    PDWeakTimer *weakTimer = [[PDWeakTimer alloc] init];
    weakTimer->_block = [block copy];
    weakTimer->_timer = [NSTimer timerWithTimeInterval:interval
                                                target:weakTimer
                                              selector:@selector(tick:)
                                              userInfo:nil
                                               repeats:repeats];
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

@interface PDLoopScrollView () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PDSwitchIndexTransactionDelegate>

@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) PDWeakTimer *timer;
@property (nonatomic, assign, readonly) CGFloat unitLen;
@property (nonatomic, assign, readonly) CGFloat curOffsetLen;
@property (nonatomic, assign, readonly) CGFloat contentLen;
@property (nonatomic, assign) CGFloat preOffsetLen;
@property (nonatomic, strong) UIView<PDLoopScrollViewPageControl> *defaultPageControl; // Not displayed on the interface, just for logic.
@property (nonatomic, strong) PDSwitchIndexQueue *transactionQueue;
@property (nonatomic, assign) BOOL isSuspended;

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
        [self setupInitializeConfiguration];
        [self createViewHierarchy];
        [self layoutContentViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupInitializeConfiguration];
        [self createViewHierarchy];
        [self layoutContentViews];
    }
    return self;
}

- (void)setupInitializeConfiguration {
    self.userInteractionEnabled = YES;
    self.collectionView.hidden = YES;
    
    _scrollEnabled = YES;
    _timeInterval = 3.f;
    _isSuspended = NO;
    _scrollDirection = PDLoopScrollViewDirectionHorizontal;
    _shouldLoopWhenSinglePage = NO;
    _transactionQueue = [[PDSwitchIndexQueue alloc] init];
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
    if (self.numberOfItems <= 0 || self.currentIndex == index) {
        return;
    }
    
    index = MAX(index, 0);
    index = MIN(index, self.numberOfItems - 1);
    [self switchToIndex:index animated:animated];
}

- (void)suspend {
    if (_isSuspended) {
        return;
    }
    
    _isSuspended = YES;
    [self.transactionQueue removeAllTransactions];
}

- (void)resume {
    if (!_isSuspended) {
        return;
    }
    
    _isSuspended = NO;
    [self repairOffsetIfNeeded];
    [self fire];
}

- (void)reloadData {
    [self.transactionQueue removeAllTransactions];
    
    // The collectionView is silently refreshed once by default
    if (self.collectionView.isHidden) {
        self.collectionView.hidden = NO;
    }
    
    self.numberOfItems = [self.dataSource numberOfItemsInScrollView:self];
    self.pageControl.numberOfPages = self.numberOfItems;
    self.defaultPageControl.numberOfPages = self.numberOfItems;
    [self.collectionView reloadData];
    
    [self fire];
}

#pragma mark - Private Methods
- (void)turnPage {
    NSInteger newIndex = self.currentIndex + 1;
    [self switchToIndex:newIndex animated:YES];
}

- (void)switchToIndex:(NSInteger)index animated:(BOOL)animated {
    [self invalidate];
    
    if (_isSuspended) {
        return;
    }
    
    PDSwitchIndexTransaction *transaction =
    [[PDSwitchIndexTransaction alloc] initWithCollectionView:self.collectionView
                                                 pageControl:self.pageControl
                                          defaultPageControl:self.defaultPageControl
                                             scrollDirection:self.scrollDirection
                                               numberOfItems:self.numberOfItems
                                                    newIndex:index
                                                    animated:animated
                                                     unitLen:self.unitLen];
    [transaction addDelegate:self];
    [self.transactionQueue addTransaction:transaction];
}

- (void)fire {
    [self invalidate];
    
    if (self.timeInterval <= 0.01f) {
        return;
    }
    
    // Check number of items
    if (self.numberOfItems == 0) {
        return;
    }
    if (self.numberOfItems == 1 && !self.shouldLoopWhenSinglePage) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.timer = [PDWeakTimer timerWithTimeInterval:self.timeInterval repeats:YES block:^{
        [weakSelf turnPage];
    }];
}

- (void)invalidate {
    [_timer invalidate];
    _timer = nil;
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

- (void)setCurrentIndex:(NSInteger)currentIndex withOptions:(PDSwitchIndexActionOptions)options {
    if (self.currentIndex == currentIndex) {
        return;
    }
    
    if (options & PDSwitchIndexActionOptionSetProperty) {
        self.currentIndex = currentIndex;
    }
    
    if (options & PDSwitchIndexActionOptionSetPageControl) {
        self.pageControl.currentPage = currentIndex;
        self.defaultPageControl.currentPage = currentIndex;
    }
    
    if (options & PDSwitchIndexActionOptionInvokeDelegate) {
        if ([self.delegate respondsToSelector:@selector(scrollView:didScrollToIndex:)]) {
            [self.delegate scrollView:self didScrollToIndex:currentIndex];
        }
    }
}

- (void)repairOffsetIfNeeded {
    if (!self.numberOfItems) {
        return;
    }
    
    // Fix: Switch tabBar or navigation push error.
    // Reason: The system will remove all CoreAnimation animations in the view not-on-screen, so that the animation cannot be completed and the rotations stay in the state of switching.
    if ((NSInteger)self.curOffsetLen % (NSInteger)self.unitLen != 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
}

#pragma mark - UICollectionView Protocols
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.numberOfItems == 0) {
        return 0;
    }
    if (self.numberOfItems == 1 && !self.shouldLoopWhenSinglePage) {
        return 1;
    }
    
    return self.numberOfItems + 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.frame.size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@", [UICollectionViewCell class]] forIndexPath:indexPath];
    
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
        NSInteger index = self.defaultPageControl.currentPage;
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
    
    self.preOffsetLen = self.curOffsetLen;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentIndex = 0;
    if (round(self.curOffsetLen / self.unitLen) >= self.numberOfItems) {
        currentIndex = 0;
    } else {
        currentIndex = self.curOffsetLen / self.unitLen;
    }
    [self setCurrentIndex:currentIndex withOptions:PDSwitchIndexActionOptionAll];
}

#pragma mark - PDSwitchIndexTransactionDelegate
- (void)didFinishExecutingTransaction:(PDSwitchIndexTransaction *)transaction {
    NSInteger pageControlIndex = transaction.pageControlIndex;
    [self setCurrentIndex:pageControlIndex withOptions:PDSwitchIndexActionOptionAll];
    
    [self repairOffsetIfNeeded];
    [self fire];
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

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.collectionView.backgroundColor = backgroundColor;
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
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%@", [UICollectionViewCell class]]];
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
    return (self.scrollDirection == PDLoopScrollViewDirectionHorizontal ?
            CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame));
}

- (CGFloat)curOffsetLen {
    return (self.scrollDirection == PDLoopScrollViewDirectionHorizontal ?
            self.collectionView.contentOffset.x : self.collectionView.contentOffset.y);
}

- (CGFloat)contentLen {
    return (self.scrollDirection == PDLoopScrollViewDirectionHorizontal ?
            self.collectionView.contentSize.width : self.collectionView.contentSize.height);
}

- (UIView<PDLoopScrollViewPageControl> *)defaultPageControl {
    if (!_defaultPageControl) {
        _defaultPageControl = (UIView<PDLoopScrollViewPageControl> *)[[UIPageControl alloc] init];
    }
    return _defaultPageControl;
}

@end
