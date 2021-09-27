//
//  PDPageControl.h
//  PDLoopScrollView
//
//  Created by liang on 2020/4/4.
//  Copyright © 2020 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PDPageControl;

@protocol PDPageControlDelegate <NSObject>

@optional
- (void)pageControl:(PDPageControl *)pageControl didSelectAtIndex:(NSInteger)index;

@end

@interface PDPageControl : UIView

@property (nonatomic, weak, nullable) id<PDPageControlDelegate> delegate;
@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hidesForSinglePage;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGSize currentPageItemSize;
@property (nonatomic, strong) UIColor *itemColor;
@property (nonatomic, strong) UIColor *currentPageItemColor;
@property (nonatomic, assign) NSTimeInterval animationDuration;

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
