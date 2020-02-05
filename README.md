# PDLoopScrollView

A cyclic scroll view supports loop scrolling, manual sliding, custom scroll direction, and custom view.

```
// Initializes the scrollView.
PDLoopScrollView *scrollView = [[PDLoopScrollView alloc] init];
// Set the delegate of <PDLoopScrollViewDelegate>.
scrollView.delegate = self;
// Set the dataSource of <PDLoopScrollViewDataSource>.
scrollView.dataSource = self;
// Set custom pageControl for scrollView.
UIView<PDLoopScrollViewPageControl> *pageControl = (UIView<PDLoopScrollViewPageControl> *)[[UIPageControll alloc] init];

scrollView.pageControl = pageControl;

// Layout scrollView and pageControl
// ...

// Implement <PDLoopScrollViewDelegate> protocol methods.

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
```
