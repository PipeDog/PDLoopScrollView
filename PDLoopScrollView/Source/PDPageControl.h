//
//  PDPageControl.h
//  PDLoopScrollView
//
//  Created by liang on 2020/4/4.
//  Copyright © 2020 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDLoopScrollView.h"

NS_ASSUME_NONNULL_BEGIN

@class PDPageControl;

@protocol PDPageControlDelegate <NSObject>

- (void)pageControl:(PDPageControl *)pageControl didSelectAtIndex:(NSUInteger)index;

@end

@interface PDPageControl : UIView <PDLoopScrollViewPageControl>

@property (nonatomic, weak, nullable) id<PDPageControlDelegate> delegate;
@property (nonatomic, assign) BOOL hidesForSinglePage;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGSize currentPageItemSize;
@property (nonatomic, strong) UIColor *itemColor;
@property (nonatomic, strong) UIColor *currentPageItemColor;

@end

NS_ASSUME_NONNULL_END
