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

@interface PDDemoPage () <PDLoopScrollViewDelegate>

@property (nonatomic, strong) PDLoopScrollView *scrollView;

@end

@implementation PDDemoPage

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.scrollView reloadData];
    
//    [self autoScroll];
}

- (void)autoScroll {
    static NSInteger index = 0;

    NSLog(@"%s", __func__);
    [self.scrollView scrollToIndex:(index % 4) animated:(index % 2)]; index += 2;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf autoScroll];
    });
}

#pragma mark - PDLoopScrollViewDelegate Methods
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
        _scrollView.secs = 2.f;
        _scrollView.scrollEnabled = YES;
        _scrollView.scrollDirection = PDLoopScrollViewDirectionHorizontal;
        [self.view addSubview:_scrollView];
        
        [_scrollView configPageControl:^(id<PDLoopScrollViewPageControlConfiguration>  _Nonnull configuration) {
            configuration.frame = CGRectMake(0, 10, CGRectGetWidth(self->_scrollView.frame), 30);
            configuration.hidden = NO;
            configuration.currentPageIndicatorTintColor = [UIColor blackColor];
            configuration.pageIndicatorTintColor = [UIColor whiteColor];
        }];
    }
    return _scrollView;
}

@end
