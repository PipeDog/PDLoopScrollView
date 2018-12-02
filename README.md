# PDLoopScrollView

A cyclic scroll view supports loop scrolling, manual sliding, custom scroll direction, and custom view.

```
// Initializes the scrollView.
PDLoopScrollView *scrollView = [[PDLoopScrollView alloc] init];
// Set the delegate of <PDLoopScrollViewDelegate>.
scrollView.delegate = self;

// Implement <PDLoopScrollViewDelegate> protocol methods.
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
```
