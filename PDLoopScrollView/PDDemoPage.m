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
    
    [self.view addSubview:self.scrollView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.scrollView reloadData];
}

#pragma mark - PDLoopScrollViewDelegate Methods
- (UIView *)scrollView:(PDLoopScrollView *)scrollView viewForViewModel:(id)viewModel {
    UILabel *label = [[UILabel alloc] init];
    label.text = (NSString *)viewModel;
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor brownColor];
    return label;
}

- (NSArray *)viewModelsForScrollView:(PDLoopScrollView *)scrollView {
    return @[@"111", @"222", @"333", @"444"];
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
        _scrollView.secs = 3.f;
        _scrollView.scrollEnabled = YES;
    }
    return _scrollView;
}

@end
