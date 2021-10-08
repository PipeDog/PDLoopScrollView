//
//  PDLoopScrollView.h
//  PipeDog
//
//  Created by liang on 2018/11/30.
//  Copyright © 2017年 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PDLoopScrollView;

@protocol PDLoopScrollViewPageControl;
@protocol PDLoopScrollViewDataSource, PDLoopScrollViewDelegate;

typedef NS_ENUM(NSUInteger, PDLoopScrollViewDirection) {
    PDLoopScrollViewDirectionHorizontal = 0,
    PDLoopScrollViewDirectionVertical
};

@interface PDLoopScrollView : UIView

@property (nonatomic, weak) id<PDLoopScrollViewDataSource> dataSource;
@property (nonatomic, weak) id<PDLoopScrollViewDelegate> delegate;

// If timeInterval is 3s, will not scroll automatically.
@property (nonatomic, assign) NSTimeInterval timeInterval;
// Control gestures scrolling, default is YES.
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
// Default is PDLoopScrollViewDirectionHorizontal.
@property (nonatomic, assign) PDLoopScrollViewDirection scrollDirection;
// Current page number.
@property (nonatomic, assign, readonly) NSInteger currentIndex;
// Whether a loop is required for a single page, deafult is NO.
@property (nonatomic, assign) BOOL shouldLoopWhenSinglePage;
// Custom page control for scrollView, default is nil.
@property (nonatomic, strong, nullable) UIView<PDLoopScrollViewPageControl> *pageControl;

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

- (void)suspend;
- (void)resume;

- (void)reloadData;

@end

@protocol PDLoopScrollViewPageControl <NSObject>

@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) NSInteger currentPage;

@end

@protocol PDLoopScrollViewDataSource <NSObject>

- (NSInteger)numberOfItemsInScrollView:(PDLoopScrollView *)scrollView;
- (nullable __kindof UIView *)scrollView:(PDLoopScrollView *)scrollView cellForItemAtIndex:(NSInteger)index;

@end

@protocol PDLoopScrollViewDelegate <NSObject>

@optional
- (void)scrollView:(PDLoopScrollView *)scrollView didSelectItemAtIndex:(NSInteger)index;
- (void)scrollView:(PDLoopScrollView *)scrollView didScrollToIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
