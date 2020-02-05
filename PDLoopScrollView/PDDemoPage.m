//
//  PDDemoPage.m
//  PDLoopScrollView
//
//  Created by liang on 2018/12/2.
//  Copyright © 2018 PipeDog. All rights reserved.
//

#import "PDDemoPage.h"
#import "PDLoopScrollView.h"
#import <Masonry/Masonry.h>

@interface PDDemoPage () <PDLoopScrollViewDataSource, PDLoopScrollViewDelegate>

@property (nonatomic, strong) UIView<PDLoopScrollViewPageControl> *pageControl;
@property (nonatomic, strong) PDLoopScrollView *scrollView;

@end

@implementation PDDemoPage

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createViewHierarchy];
    [self layoutContentViews];
    [self.scrollView reloadData];
}

- (void)createViewHierarchy {
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.pageControl];
}

- (void)layoutContentViews {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(100.f);
        make.left.mas_equalTo(20.f);
        make.height.mas_equalTo(150.f);
        make.right.equalTo(self.view.mas_right).offset(-20.f);
    }];
    
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40.f);
        make.left.bottom.and.right.equalTo(self.scrollView);
    }];
}

#pragma mark - PDLoopScrollViewDataSource
- (NSInteger)numberOfItemsInScrollView:(PDLoopScrollView *)scrollView {
    return self.dataSource.count;
}

- (UIView *)scrollView:(PDLoopScrollView *)scrollView cellForItemAtIndex:(NSInteger)index {
    NSArray *dataSource = self.dataSource[index];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = dataSource[0];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = dataSource[1];
    return label;
}

#pragma mark - PDLoopScrollViewDelegate
- (void)scrollView:(PDLoopScrollView *)scrollView didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"%s, index = %zd", __func__, index);
}

- (void)scrollView:(PDLoopScrollView *)scrollView didScrollToIndex:(NSInteger)index {
    NSLog(@"%s, index = %zd", __func__, index);
}

#pragma mark - Getter Methods
- (NSArray *)dataSource {
    return @[@[@"000", [UIColor magentaColor]],
             @[@"111", [UIColor blueColor]],
             @[@"222", [UIColor yellowColor]],
             @[@"333", [UIColor cyanColor]]];
}

- (PDLoopScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[PDLoopScrollView alloc] initWithFrame:CGRectMake(20, 100, CGRectGetWidth(self.view.frame) - 40, 150)];
        _scrollView.backgroundColor = [UIColor lightGrayColor];
        _scrollView.delegate = self;
        _scrollView.dataSource = self;
        _scrollView.secs = 2.f;
        _scrollView.scrollEnabled = YES;
        _scrollView.scrollDirection = PDLoopScrollViewDirectionHorizontal;
        _scrollView.pageControl = self.pageControl;
    }
    return _scrollView;
}

- (UIView<PDLoopScrollViewPageControl> *)pageControl {
    if (!_pageControl) {
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        pageControl.hidesForSinglePage = YES;
        
        _pageControl = (UIView<PDLoopScrollViewPageControl> *)pageControl;
    }
    return _pageControl;
}

@end
