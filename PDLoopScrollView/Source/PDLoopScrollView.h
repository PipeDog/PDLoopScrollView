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

typedef NS_ENUM(NSUInteger, PDLoopScrollViewDirection) {
    PDLoopScrollViewDirectionHorizontal = 0,
    PDLoopScrollViewDirectionVertical
};

@protocol PDLoopScrollViewDelegate <NSObject>

- (NSInteger)numberOfItemsInScrollView:(PDLoopScrollView *)scrollView;
- (nullable UIView *)scrollView:(PDLoopScrollView *)scrollView cellForItemAtIndex:(NSInteger)index;

@optional
- (void)scrollView:(PDLoopScrollView *)scrollView didSelectItemAtIndex:(NSInteger)index;
- (void)scrollView:(PDLoopScrollView *)scrollView didScrollToIndex:(NSInteger)index;

@end

@interface PDLoopScrollViewPageControlConfiguration : NSObject

@property (nonatomic) CGRect frame;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, strong, nullable) UIColor *pageIndicatorTintColor;
@property (nonatomic, strong, nullable) UIColor *currentPageIndicatorTintColor;

@end

@interface PDLoopScrollView : UIView

@property (nonatomic, weak) id<PDLoopScrollViewDelegate> delegate;

// If secs is 0s, will not scroll automatically.
@property (nonatomic, assign) NSTimeInterval secs;
// Control gestures scrolling, default is YES.
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
// Default is PDLoopScrollViewDirectionHorizontal.
@property (nonatomic, assign) PDLoopScrollViewDirection scrollDirection;
// Current page number.
@property (nonatomic, assign, readonly) NSInteger currentIndex;

- (void)configPageControl:(void (^)(PDLoopScrollViewPageControlConfiguration *configuration))block;

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
