//
//  TBCollectionViewHelper.m
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import "TBCollectionViewFlowLayout.h"
#import "TBSpringBoardView.h"
#import "TBCollectionViewCell.h"

static CGFloat const PRESS_TO_MOVE_MIN_DURATION = 0.1;
static CGFloat const MIN_PRESS_TO_BEGIN_EDITING_DURATION = 0.6;

CG_INLINE CGPoint CGPointOffset(CGPoint point, CGFloat dx, CGFloat dy)
{
    return CGPointMake(point.x + dx, point.y + dy);
}

@interface TBCollectionViewFlowLayout() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer   *longPressGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer         *panGestureRecognizer;

@property (nonatomic, assign) BOOL editing;
@property (nonatomic, assign) BOOL isOutOfFolder;

@end

@implementation TBCollectionViewFlowLayout
{
    NSIndexPath                  *_movingItemIndexPath;
    NSIndexPath                  *_movingItemIndexPathInFolder;
    UIView                       *_beingMovedPromptView;
    CGPoint                      _sourceItemCollectionViewCellCenter;
    CGPoint                      _sourceItemCollectionViewCellCenterInFolder;
    
    CADisplayLink                *_displayLink;
    CFTimeInterval               _remainSecondsToBeginEditing;
}

#pragma mark - setup
- (void)dealloc
{
    [_displayLink invalidate];
    
    [self removeGestureRecognizers];
    [self removeObserver:self forKeyPath:@"collectionView"];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [self addObserver:self forKeyPath:@"collectionView" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)addGestureRecognizers
{
    self.collectionView.userInteractionEnabled = YES;
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerTriggerd:)];
    _longPressGestureRecognizer.cancelsTouchesInView = NO;
    _longPressGestureRecognizer.minimumPressDuration = PRESS_TO_MOVE_MIN_DURATION;
    _longPressGestureRecognizer.delegate = self;
    
    for (UIGestureRecognizer * gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerTriggerd:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)removeGestureRecognizers
{
    if (_longPressGestureRecognizer) {
        if (_longPressGestureRecognizer.view) {
            [_longPressGestureRecognizer.view removeGestureRecognizer:_longPressGestureRecognizer];
        }
        _longPressGestureRecognizer = nil;
    }
    
    if (_panGestureRecognizer) {
        if (_panGestureRecognizer.view) {
            [_panGestureRecognizer.view removeGestureRecognizer:_panGestureRecognizer];
        }
        _panGestureRecognizer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - getter and setter implementation
- (id<TBCollectionViewFlowLayoutDataSource>)dataSource
{
    return (id<TBCollectionViewFlowLayoutDataSource>)self.collectionView.dataSource;
}

- (void)setEditing:(BOOL)editing
{
    TBSpringBoardView *springBoardView = (TBSpringBoardView *)self.collectionView;
    springBoardView.editing = editing;
    
    if (!self.folderView.hidden) {
        ((TBSpringBoardView *)self.folderView).editing = editing;
    }
}

- (BOOL)editing
{
    TBSpringBoardView * springBoardView = (TBSpringBoardView *)self.collectionView;
    return springBoardView.editing;
}

#pragma mark - override UICollectionViewLayout methods
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray * layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes * layoutAttributes in layoutAttributesForElementsInRect) {
        
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            layoutAttributes.hidden = [layoutAttributes.indexPath isEqual:_movingItemIndexPath];
        }
    }
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes * layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        layoutAttributes.hidden = [layoutAttributes.indexPath isEqual:_movingItemIndexPath];
    }
    return layoutAttributes;
}

#pragma mark - gesture
- (void)setPanGestureRecognizerEnable:(BOOL)panGestureRecognizerEnable
{
    _panGestureRecognizer.enabled = panGestureRecognizerEnable;
}

- (BOOL)panGestureRecognizerEnable
{
    return _panGestureRecognizer.enabled;
}

- (void)longPressGestureRecognizerTriggerd:(UILongPressGestureRecognizer *)longPress
{
    switch (longPress.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        {
            if (_displayLink == nil) {
                _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTriggered:)];
                _displayLink.frameInterval = 6;
                [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                
                _remainSecondsToBeginEditing = MIN_PRESS_TO_BEGIN_EDITING_DURATION;
            }
            
            if (self.editing == NO) {
                return;
            }
            
            CGPoint point = [longPress locationInView:self.desktopView];
            CGPoint positionInFolder = [self.folderView convertPoint:point fromView:self.desktopView];
            
            if ([self.folderView pointInside:positionInFolder withEvent:nil]) {
                [self folderViewLongPressBegin:positionInFolder];
            } else {
                [self desktopViewLongPressBegin:point];
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            [_beingMovedPromptView removeFromSuperview];
            _beingMovedPromptView = nil;
            [self invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (void)folderViewLongPressBegin:(CGPoint)positionInFolder
{
    _movingItemIndexPathInFolder = [self.folderView indexPathForItemAtPoint:positionInFolder];
    UICollectionViewCell * sourceCollectionViewCell = [self.folderView cellForItemAtIndexPath:_movingItemIndexPathInFolder];
    TBCollectionViewCell * sourceGridViewCell = (TBCollectionViewCell *)sourceCollectionViewCell;
    
    _beingMovedPromptView = [[UIView alloc] initWithFrame:CGRectOffset(sourceCollectionViewCell.frame, DELETE_ICON_CORNER_RADIUS, DELETE_ICON_CORNER_RADIUS)];
    
    sourceCollectionViewCell.highlighted = YES;
    UIView * highlightedSnapshotView = [sourceGridViewCell snapshotView];
    highlightedSnapshotView.frame = sourceGridViewCell.bounds;
    highlightedSnapshotView.alpha = 1;
    
    sourceCollectionViewCell.highlighted = NO;
    UIView * snapshotView = [sourceGridViewCell snapshotView];
    snapshotView.frame = sourceGridViewCell.bounds;
    snapshotView.alpha = 0;
    
    [_beingMovedPromptView addSubview:snapshotView];
    [_beingMovedPromptView addSubview:highlightedSnapshotView];
    [self.folderView addSubview:_beingMovedPromptView];
    
    _sourceItemCollectionViewCellCenterInFolder = sourceCollectionViewCell.center;
    
    typeof(self) __weak weakSelf = self;
    [UIView animateWithDuration:0
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         typeof(self) __strong strongSelf = weakSelf;
                         if (strongSelf) {
                             highlightedSnapshotView.alpha = 0;
                             snapshotView.alpha = 1;
                         }
                     }
                     completion:^(BOOL finished) {
                         
                         typeof(self) __strong strongSelf = weakSelf;
                         if (strongSelf) {
                             [highlightedSnapshotView removeFromSuperview];
                         }
                     }
     ];
    [self invalidateLayout];
}

- (void)panGestureRecognizerTriggerd:(UIPanGestureRecognizer *)pan
{
    if (self.editing == NO) {
        return;
    }
    switch (pan.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            if ([_beingMovedPromptView.superview isEqual:self.desktopView]) {
                
                [self desktopViewPanChange:pan];
                
            } else {
                
                [self folderViewPanChange:pan];
                
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if ([_beingMovedPromptView.superview isEqual:self.desktopView]) {
                
                [self desktopViewPanEnd:pan];
                
            } else {
                
                [self folderViewPanEnd:pan];
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (void)desktopViewPanChange:(UIPanGestureRecognizer *)pan
{
    if (_isOutOfFolder) {
        CGPoint panTranslation = [pan locationInView:self.desktopView];
        _beingMovedPromptView.center = CGPointOffset(CGPointZero, panTranslation.x, panTranslation.y);
        
        CGPoint destinationPointEntry = CGPointMake(_beingMovedPromptView.center.x + _beingMovedPromptView.frame.size.width/2, _beingMovedPromptView.center.y);
        NSIndexPath * sourceIndexPath = _movingItemIndexPath;
        NSIndexPath * destinationIndexPath = [self.desktopView indexPathForItemAtPoint:destinationPointEntry];
        
        if ((destinationIndexPath == nil) || [destinationIndexPath isEqual:sourceIndexPath]) {
            return;
        }
        if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemFromIndexPath:toIndexPath:)] && ![self.dataSource collectionView:self.desktopView canMoveItemFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath]) {
            return;
        }
        
        // 判断是否为合并成文件夹
        UICollectionViewCell *destinationCell = [self.desktopView cellForItemAtIndexPath:destinationIndexPath];
        
        if (CGRectContainsPoint(destinationCell.frame, _beingMovedPromptView.center)) {
            return;
        }
        
        if ([self.dataSource respondsToSelector:@selector(collectionView:willMoveItemFromIndexPath:toIndexPath:)]) {
            [self.dataSource collectionView:self.desktopView willMoveItemFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
        }
        
        _movingItemIndexPath = destinationIndexPath;
        
        typeof(self) __weak weakSelf = self;
        [self.desktopView performBatchUpdates:^{
            typeof(self) __strong strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf.desktopView deleteItemsAtIndexPaths:@[sourceIndexPath]];
                [strongSelf.desktopView insertItemsAtIndexPaths:@[destinationIndexPath]];
            }
        } completion:^(BOOL finished) {

        }];
        return;
    }
    CGPoint panTranslation = [pan translationInView:_beingMovedPromptView.superview];
    
    _beingMovedPromptView.center = CGPointOffset(_sourceItemCollectionViewCellCenter, panTranslation.x, panTranslation.y);
    CGPoint destinationPointEntry = CGPointMake(_beingMovedPromptView.center.x + _beingMovedPromptView.frame.size.width/2, _beingMovedPromptView.center.y);
    NSIndexPath * sourceIndexPath = _movingItemIndexPath;
    NSIndexPath * destinationIndexPath = [self.desktopView indexPathForItemAtPoint:destinationPointEntry];
    
    if ((destinationIndexPath == nil) || [destinationIndexPath isEqual:sourceIndexPath]) {
        return;
    }
    if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemFromIndexPath:toIndexPath:)] && ![self.dataSource collectionView:self.desktopView canMoveItemFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath]) {
        return;
    }
    
    // 判断是否为合并成文件夹
    UICollectionViewCell *destinationCell = [self.desktopView cellForItemAtIndexPath:destinationIndexPath];
    
    if (CGRectContainsPoint(destinationCell.frame, _beingMovedPromptView.center)) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:willMoveItemFromIndexPath:toIndexPath:)]) {
        [self.dataSource collectionView:self.desktopView willMoveItemFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
    
    _movingItemIndexPath = destinationIndexPath;
    
    typeof(self) __weak weakSelf = self;
    [self.desktopView performBatchUpdates:^{
        typeof(self) __strong strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.desktopView deleteItemsAtIndexPaths:@[sourceIndexPath]];
            [strongSelf.desktopView insertItemsAtIndexPaths:@[destinationIndexPath]];
        }
    } completion:^(BOOL finished) {

    }];
}

- (void)folderViewPanChange:(UIPanGestureRecognizer *)pan
{
    TBCollectionViewCell *cell = (TBCollectionViewCell *)[self.folderView cellForItemAtIndexPath:_movingItemIndexPathInFolder];
    if (cell) {
        UICollectionViewLayoutAttributes * layoutAttributes = [self.folderView layoutAttributesForItemAtIndexPath:_movingItemIndexPathInFolder];
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            layoutAttributes.hidden = [layoutAttributes.indexPath isEqual:_movingItemIndexPathInFolder];
        }
        [self.folderView.collectionViewLayout invalidateLayout];
    }
    CGPoint panTranslation = [pan translationInView:_beingMovedPromptView.superview];
    _beingMovedPromptView.center = CGPointOffset(_sourceItemCollectionViewCellCenterInFolder, panTranslation.x, panTranslation.y);
    //判断是否拖出当前collectionview
    if (_beingMovedPromptView.center.x < 0 ||
        _beingMovedPromptView.center.y < 0 ||
        _beingMovedPromptView.center.x > self.folderView.frame.size.width ||
        _beingMovedPromptView.center.y > self.folderView.frame.size.height) {
        _isOutOfFolder = YES;
        
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(collectionView:willMoveItemAtIndexPathOutofEdge:)]) {
            [self.dataSource collectionView:self.folderView willMoveItemAtIndexPathOutofEdge:_movingItemIndexPathInFolder];
        }
        
        _movingItemIndexPath = [NSIndexPath indexPathForItem:([self.desktopView numberOfItemsInSection:0] - 2) inSection:0];
        [_beingMovedPromptView removeFromSuperview];
        [self.desktopView addSubview:_beingMovedPromptView];
        
        _movingItemIndexPathInFolder = nil;
        _sourceItemCollectionViewCellCenterInFolder = CGPointZero;
        [self invalidateLayout];
        return;
    }
    
    CGPoint destinationPointEntry = CGPointMake(_beingMovedPromptView.center.x + _beingMovedPromptView.frame.size.width/2, _beingMovedPromptView.center.y);
    NSIndexPath * sourceIndexPath = _movingItemIndexPathInFolder;
    NSIndexPath * destinationIndexPath = [self.folderView indexPathForItemAtPoint:destinationPointEntry];
    
    if ((destinationIndexPath == nil) || [destinationIndexPath isEqual:sourceIndexPath]) {
        return;
    }
    if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemFromIndexPath:toIndexPath:)] && ![self.dataSource collectionView:self.folderView canMoveItemFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath]) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:willMoveItemFromIndexPath:toIndexPath:)]) {
        [self.dataSource collectionView:self.folderView willMoveItemFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
    
    _movingItemIndexPathInFolder = destinationIndexPath;
    
    typeof(self) __weak weakSelf = self;
    [self.folderView performBatchUpdates:^{
        typeof(self) __strong strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.folderView deleteItemsAtIndexPaths:@[sourceIndexPath]];
            [strongSelf.folderView insertItemsAtIndexPaths:@[destinationIndexPath]];
        }
    } completion:^(BOOL finished) {

    }];
}

- (void)desktopViewPanEnd:(UIPanGestureRecognizer *)pan
{
    if (_isOutOfFolder) {
        _isOutOfFolder = NO;
        [_displayLink invalidate];
        _displayLink = nil;
        
        NSIndexPath * movingItemIndexPath = _movingItemIndexPath;
        
        if (movingItemIndexPath) {
            
            _movingItemIndexPath = nil;
            _sourceItemCollectionViewCellCenter = CGPointZero;
            
            UICollectionViewLayoutAttributes * movingItemCollectionViewLayoutAttributes = [self layoutAttributesForItemAtIndexPath:movingItemIndexPath];
            
            _longPressGestureRecognizer.enabled = NO;
            
            typeof(self) __weak weakSelf = self;
            [UIView animateWithDuration:0
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 typeof(self) __strong strongSelf = weakSelf;
                                 if (strongSelf) {
                                     _beingMovedPromptView.center = movingItemCollectionViewLayoutAttributes.center;
                                 }
                             }
                             completion:^(BOOL finished) {
                                 
                                 _longPressGestureRecognizer.enabled = YES;
                                 
                                 typeof(self) __strong strongSelf = weakSelf;
                                 if (strongSelf) {
                                     [_beingMovedPromptView removeFromSuperview];
                                     _beingMovedPromptView = nil;
                                     [strongSelf invalidateLayout];
                                 }
                             }];
        }
        
        
        return;
    }
    CGPoint panTranslation = [pan translationInView:self.desktopView];
    _beingMovedPromptView.center = CGPointOffset(_sourceItemCollectionViewCellCenter, panTranslation.x, panTranslation.y);
    
    CGPoint destinationPointEntry = CGPointMake(_beingMovedPromptView.center.x + _beingMovedPromptView.frame.size.width/2, _beingMovedPromptView.center.y);
    NSIndexPath * destinationIndexPath = [self.desktopView indexPathForItemAtPoint:destinationPointEntry];
    
    // 判断是否为合并成文件夹
    TBCollectionViewCell *destinationCell = (TBCollectionViewCell *)[self.desktopView cellForItemAtIndexPath:destinationIndexPath];
    
    if (CGRectContainsPoint(destinationCell.frame, _beingMovedPromptView.center)) {
        
        NSIndexPath * sourceIndexPath = _movingItemIndexPath;
        if ([self.dataSource respondsToSelector:@selector(collectionView:didMoveItemFromIndexPath:intoIndexPath:)]) {
            [self.dataSource collectionView:self.desktopView didMoveItemFromIndexPath:sourceIndexPath intoIndexPath:destinationIndexPath];
        }
        
        typeof(self) __weak weakSelf = self;
        [self.desktopView performBatchUpdates:^{
            typeof(self) __strong strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf.desktopView deleteItemsAtIndexPaths:@[sourceIndexPath]];
            }
        } completion:^(BOOL finished) {
        }];
    }
    
    [_displayLink invalidate];
    _displayLink = nil;
    
    NSIndexPath * movingItemIndexPath = _movingItemIndexPath;
    
    if (movingItemIndexPath) {
        
        _movingItemIndexPath = nil;
        _sourceItemCollectionViewCellCenter = CGPointZero;
        
        UICollectionViewLayoutAttributes * movingItemCollectionViewLayoutAttributes = [self layoutAttributesForItemAtIndexPath:movingItemIndexPath];
        
        _longPressGestureRecognizer.enabled = NO;
        
        typeof(self) __weak weakSelf = self;
        [UIView animateWithDuration:0
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             typeof(self) __strong strongSelf = weakSelf;
                             if (strongSelf) {
                                 _beingMovedPromptView.center = movingItemCollectionViewLayoutAttributes.center;
                             }
                         }
                         completion:^(BOOL finished) {
                             
                             _longPressGestureRecognizer.enabled = YES;
                             
                             typeof(self) __strong strongSelf = weakSelf;
                             if (strongSelf) {
                                 [_beingMovedPromptView removeFromSuperview];
                                 _beingMovedPromptView = nil;
                                 [strongSelf invalidateLayout];
                             }
                         }];
    }
}

- (void)folderViewPanEnd:(UIPanGestureRecognizer *)pan
{
    CGPoint panTranslation = [pan translationInView:self.folderView];
    
    _beingMovedPromptView.center = CGPointOffset(_sourceItemCollectionViewCellCenterInFolder, panTranslation.x, panTranslation.y);
    
    [_displayLink invalidate];
    _displayLink = nil;
    
    NSIndexPath * movingItemIndexPath = _movingItemIndexPathInFolder;
    
    if (movingItemIndexPath) {
        
        _movingItemIndexPathInFolder = nil;
        _sourceItemCollectionViewCellCenterInFolder = CGPointZero;
        
        UICollectionViewLayoutAttributes * movingItemCollectionViewLayoutAttributes = [self layoutAttributesForItemAtIndexPath:movingItemIndexPath];
        
        _longPressGestureRecognizer.enabled = NO;
        
        typeof(self) __weak weakSelf = self;
        [UIView animateWithDuration:0
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             typeof(self) __strong strongSelf = weakSelf;
                             if (strongSelf) {
                                 _beingMovedPromptView.center = movingItemCollectionViewLayoutAttributes.center;
                             }
                         }
                         completion:^(BOOL finished) {
                             
                             _longPressGestureRecognizer.enabled = YES;
                             
                             typeof(self) __strong strongSelf = weakSelf;
                             if (strongSelf) {
                                 [_beingMovedPromptView removeFromSuperview];
                                 _beingMovedPromptView = nil;
                                 [strongSelf invalidateLayout];
                             }
                         }];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_panGestureRecognizer isEqual:gestureRecognizer] && self.editing) {
        return _movingItemIndexPath != nil || _movingItemIndexPathInFolder != nil;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    //  only _longPressGestureRecognizer and _panGestureRecognizer can recognize simultaneously
    if ([_longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [_panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    if ([_panGestureRecognizer isEqual:gestureRecognizer]) {
        return [_longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    return NO;
}

- (void)desktopViewLongPressBegin:(CGPoint)point
{
    _movingItemIndexPath = [self.desktopView indexPathForItemAtPoint:point];
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] && [self.dataSource collectionView:self.desktopView canMoveItemAtIndexPath:_movingItemIndexPath] == NO) {
        _movingItemIndexPath = nil;
        return;
    }
    
    UICollectionViewCell * sourceCollectionViewCell = [self.desktopView cellForItemAtIndexPath:_movingItemIndexPath];
    TBCollectionViewCell * sourceGridViewCell = (TBCollectionViewCell *)sourceCollectionViewCell;
    
    _beingMovedPromptView = [[UIView alloc] initWithFrame:CGRectOffset(sourceCollectionViewCell.frame, DELETE_ICON_CORNER_RADIUS, DELETE_ICON_CORNER_RADIUS)];
    
    sourceCollectionViewCell.highlighted = YES;
    UIView * highlightedSnapshotView = [sourceGridViewCell snapshotView];
    highlightedSnapshotView.frame = sourceGridViewCell.bounds;
    highlightedSnapshotView.alpha = 1;
    
    sourceCollectionViewCell.highlighted = NO;
    UIView * snapshotView = [sourceGridViewCell snapshotView];
    snapshotView.frame = sourceGridViewCell.bounds;
    snapshotView.alpha = 0;
    
    [_beingMovedPromptView addSubview:snapshotView];
    [_beingMovedPromptView addSubview:highlightedSnapshotView];
    [self.desktopView addSubview:_beingMovedPromptView];
    
    _sourceItemCollectionViewCellCenter = sourceCollectionViewCell.center;
    
    typeof(self) __weak weakSelf = self;
    [UIView animateWithDuration:0
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         typeof(self) __strong strongSelf = weakSelf;
                         if (strongSelf) {
                             highlightedSnapshotView.alpha = 0;
                             snapshotView.alpha = 1;
                         }
                     }
                     completion:^(BOOL finished) {
                         
                         typeof(self) __strong strongSelf = weakSelf;
                         if (strongSelf) {
                             [highlightedSnapshotView removeFromSuperview];
                         }
                     }
     ];
    [self invalidateLayout];
}

#pragma mark - displayLink
- (void)displayLinkTriggered:(CADisplayLink *)displayLink
{
    if (_remainSecondsToBeginEditing <= 0) {
        
        self.editing = YES;
        [_displayLink invalidate];
        _displayLink = nil;
    }
    
    _remainSecondsToBeginEditing = _remainSecondsToBeginEditing - 0.1;
}

#pragma mark - KVO and notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"collectionView"]) {
        if (self.collectionView) {
            [self addGestureRecognizers];
        }
        else {
            [self removeGestureRecognizers];
        }
    }
}

- (void)applicationWillResignActive:(NSNotification *)notificaiton
{
    _panGestureRecognizer.enabled = NO;
    _panGestureRecognizer.enabled = YES;
}

@end
