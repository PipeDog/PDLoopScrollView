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
}

#pragma mark - PDLoopScrollViewDelegate Methods
- (UIView *)scrollView:(PDLoopScrollView *)scrollView viewForViewModel:(id)viewModel {
    NSArray *dataSource = (NSArray *)viewModel;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = dataSource[0];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = dataSource[1];
    return label;
}

- (NSArray *)viewModelsForScrollView:(PDLoopScrollView *)scrollView {
    return @[@[@"111", [UIColor magentaColor]],
             @[@"222", [UIColor blueColor]],
             @[@"333", [UIColor yellowColor]],
             @[@"444", [UIColor cyanColor]]];
}

- (void)scrollView:(PDLoopScrollView *)scrollView didSelectItemOfViewModel:(id)viewModel {
    NSLog(@"viewModel = %@", viewModel);
}

#pragma mark - Getter Methods
- (PDLoopScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[PDLoopScrollView alloc] initWithFrame:CGRectMake(20, 100, CGRectGetWidth(self.view.frame) - 40, 150)];
        _scrollView.backgroundColor = [UIColor lightGrayColor];
        _scrollView.delegate = self;
        _scrollView.secs = 2.f;
        _scrollView.scrollEnabled = YES;
        _scrollView.scrollDirection = PDLoopScrollViewDirectionVertical;
        [self.view addSubview:_scrollView];
        
        [_scrollView configPageControl:^(PDLoopScrollViewPageControlConfiguration * _Nonnull configuration) {
            configuration.frame = CGRectMake(0, 10, CGRectGetWidth(self->_scrollView.frame), 30);
            configuration.hidden = NO;
            configuration.currentPageIndicatorTintColor = [UIColor blackColor];
            configuration.pageIndicatorTintColor = [UIColor whiteColor];
        }];
    }
    return _scrollView;
}

@end
