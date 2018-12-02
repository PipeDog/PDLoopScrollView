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

- (UIView *)scrollView:(PDLoopScrollView *)scrollView viewForViewModel:(id)viewModel;

- (NSArray *)viewModelsForScrollView:(PDLoopScrollView *)scrollView;

@optional

- (void)scrollView:(PDLoopScrollView *)scrollView didSelectItemOfViewModel:(id)viewModel;

@end

@interface PDLoopScrollView : UIView

@property (nonatomic, weak) id<PDLoopScrollViewDelegate> delegate;

// If secs is 0s, will not scroll automatically.
@property (nonatomic, assign) NSTimeInterval secs;
// Control gestures scrolling, default is YES.
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
// Default is PDLoopScrollViewDirectionHorizontal.
@property (nonatomic, assign) PDLoopScrollViewDirection scrollDirection;
// Default is NO.
@property (nonatomic, assign) BOOL hidePageControl;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END