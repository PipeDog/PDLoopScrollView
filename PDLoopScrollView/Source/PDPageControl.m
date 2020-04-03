//
//  PDPageControl.m
//  PDLoopScrollView
//
//  Created by liang on 2020/4/4.
//  Copyright © 2020 PipeDog. All rights reserved.
//

#import "PDPageControl.h"

@interface PDPageControlItem : UIControl

@property (nonatomic, assign) NSUInteger index;

@end

@implementation PDPageControlItem

@end

@interface PDPageControl ()

@property (nonatomic, strong) NSArray<UIView *> *pageControlItems;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *containerLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *containerRightConstraint;
@property (nonatomic, copy) NSArray<NSArray<NSLayoutConstraint *> *> *pageControlItemsConstraints;

@end

@implementation PDPageControl

@synthesize currentPage = _currentPage;
@synthesize numberOfPages = _numberOfPages;

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _commitInit];
        [self _createViewHierarchy];
        [self _layoutContentViews];
    }
    return self;
}

- (void)_commitInit {
    self.backgroundColor = [UIColor clearColor];

    _currentPage = 0;
    _numberOfPages = 0;
    _hidesForSinglePage = YES;
    _itemSpacing = 5.f;
    _itemSize = CGSizeMake(6.f, 3.f);
    _currentPageItemSize = CGSizeMake(12.f, 3.f);
    _itemColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    _currentPageItemColor = [UIColor whiteColor];
}

- (void)_createViewHierarchy {
    [self addSubview:self.containerView];
}

- (void)_layoutContentViews {
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.containerView.heightAnchor constraintEqualToAnchor:self.heightAnchor],
    ]];
}

#pragma mark - Tool Methods
- (void)_forceUpdateConstraints {
    [self _deactivateConstraints];
    [self _layoutPageControlItems];
    [self _layoutContainerView];
}

- (void)_removeAllPageControlItems {
    [self.pageControlItems makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)_createPageControlItemsIfNeeded {
    if (self.pageControlItems.count == self.numberOfPages) {
        return;
    }
    
    NSMutableArray *pageControlItems = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < _numberOfPages; i++) {
        PDPageControlItem *pageControlItem = [[PDPageControlItem alloc] init];
        pageControlItem.index = i;
        pageControlItem.translatesAutoresizingMaskIntoConstraints = NO;
        [pageControlItem addTarget:self action:@selector(_didClickPageControlItem:) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:pageControlItem];
        
        [pageControlItems addObject:pageControlItem];
    }
    
    self.pageControlItems = [pageControlItems copy];
}

- (void)_layoutPageControlItems {
    self.pageControlItemsConstraints = nil;
    
    CGFloat totalWidth = 0;
    NSMutableArray *pageControlItemsConstraints = [NSMutableArray array];
    NSUInteger count = self.pageControlItems.count;
    
    for (NSUInteger i = 0; i < count; i++) {
        UIView *pageControlItem = self.pageControlItems[i];
        pageControlItem.backgroundColor = (i == self.currentPage ? self.currentPageItemColor : self.itemColor);
        
        CGSize size = (i == self.currentPage ? self.currentPageItemSize : self.itemSize);
        pageControlItem.layer.cornerRadius = MIN(size.width, size.height) / 2.f;

        CGFloat left = totalWidth + self.itemSpacing * i;
        totalWidth += size.width;
                
        NSArray<NSLayoutConstraint *> *constraints = @[
            [pageControlItem.widthAnchor constraintEqualToConstant:size.width],
            [pageControlItem.heightAnchor constraintEqualToConstant:size.height],
            [pageControlItem.leftAnchor constraintEqualToAnchor:self.containerView.leftAnchor constant:left],
            [pageControlItem.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],
        ];
        
        [NSLayoutConstraint activateConstraints:constraints];
        [pageControlItemsConstraints addObject:constraints];
    }
    
    self.pageControlItemsConstraints = [pageControlItemsConstraints copy];
}

- (void)_layoutContainerView {
    UIView *firstItem = self.pageControlItems.firstObject;
    UIView *lastItem = self.pageControlItems.lastObject;
    
    self.containerLeftConstraint = [self.containerView.leftAnchor constraintEqualToAnchor:firstItem.leftAnchor];
    self.containerRightConstraint = [self.containerView.rightAnchor constraintEqualToAnchor:lastItem.rightAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
        self.containerLeftConstraint,
        self.containerRightConstraint,
    ]];
}

- (void)_deactivateConstraints {
    self.containerLeftConstraint.active = NO;
    self.containerRightConstraint.active = NO;

    for (NSArray<NSLayoutConstraint *> *constraints in [self.pageControlItemsConstraints copy]) {
        [NSLayoutConstraint deactivateConstraints:constraints];
    }
}

#pragma mark - Event Methods
- (void)_didClickPageControlItem:(PDPageControlItem *)pageControlItem {
    if ([self.delegate respondsToSelector:@selector(pageControl:didSelectAtIndex:)]) {
        [self.delegate pageControl:self didSelectAtIndex:pageControlItem.index];
    }
}

#pragma mark - Setter Methods
- (void)setNumberOfPages:(NSInteger)numberOfPages {
    _numberOfPages = numberOfPages;
    [self _removeAllPageControlItems];

    if (_numberOfPages <= 1 && self.hidesForSinglePage) {
        return;
    }
    
    [self _createPageControlItemsIfNeeded];
    [self _forceUpdateConstraints];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = currentPage;
    [self _forceUpdateConstraints];
}

#pragma mark - Getter Methods
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _containerView;
}

@end
