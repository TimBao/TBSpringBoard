//
//  ViewController.m
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import "ViewController.h"
#import "TBCollectionViewCell.h"
#import "TBCollectionViewFlowLayout.h"
#import "TBPopupFolderView.h"
#import "TBSpringBoardView.h"

#import "Masonry.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, TBCollectionViewFlowLayoutDataSource, TBCollectionViewCellDelegate, TBPopupFolderViewDelegate>

@property (nonatomic, strong) TBSpringBoardView          *springBoardView;
@property (nonatomic, strong) TBPopupFolderView          *popupFolderView;
@property (nonatomic, strong) TBCollectionViewFlowLayout *collectionViewFlowLayout;

@property (nonatomic, strong) NSMutableArray             *allBoards;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSMutableArray *folderData = [NSMutableArray arrayWithArray:@[[UIColor orangeColor], [UIColor grayColor]]];
    
    NSArray *originData = @[[UIColor redColor],
                            [UIColor yellowColor],
                            [UIColor blueColor],
                            folderData,
                            [UIColor blackColor]
                           ];
    self.allBoards = [NSMutableArray arrayWithArray:originData];
    
    _collectionViewFlowLayout = [[TBCollectionViewFlowLayout alloc] init];
    _collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    _collectionViewFlowLayout.minimumLineSpacing = 20;
    _collectionViewFlowLayout.itemSize = CGSizeMake(60, 80);
    
    _springBoardView = [[TBSpringBoardView alloc] initWithFrame:self.view.bounds collectionViewLayout:_collectionViewFlowLayout];
    _springBoardView.contentInset           = UIEdgeInsetsMake(0, 0, 0, 0);
    _springBoardView.delegate               = self;
    _springBoardView.dataSource             = self;
    _springBoardView.scrollEnabled          = NO;
    _springBoardView.backgroundColor        = [UIColor purpleColor];
    _springBoardView.userInteractionEnabled = YES;
    [self.view addSubview:_springBoardView];
    
    [_springBoardView registerClass:[TBCollectionViewCell class] forCellWithReuseIdentifier:DequeueReusableCell];

    [_springBoardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _popupFolderView = [[TBPopupFolderView alloc] init];
    _popupFolderView.delegate = self;
    _popupFolderView.backgroundColor = [UIColor whiteColor];
    _popupFolderView.userInteractionEnabled = YES;
    _popupFolderView.collectionView.delegate = self;
    _popupFolderView.collectionView.dataSource = self;
    [_springBoardView addSubview:_popupFolderView];
    [_springBoardView bringSubviewToFront:_popupFolderView];
    _popupFolderView.hidden = YES;
    [_popupFolderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _collectionViewFlowLayout.desktopView = _springBoardView;
    _collectionViewFlowLayout.folderView  = _popupFolderView.collectionView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([collectionView isEqual:_springBoardView]) {
        return self.allBoards.count;
    }
    return _popupFolderView.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:_springBoardView]) {
        TBCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:DequeueReusableCell forIndexPath:indexPath];
        [cell reset];
        cell.delegate = self;
        cell.editing = _springBoardView.editing;
        
        id data = self.allBoards[indexPath.item];
        if ([data isKindOfClass:[NSArray class]]) {
            NSMutableArray *array = data;
            if (array.count == 1) {
                UIColor *color = array[0];
                cell.icons = nil;
                cell.title = @"Test";
                [cell.iconImageView setBackgroundColor:(UIColor *)color];

                [self.allBoards replaceObjectAtIndex:indexPath.item withObject:color];
            } else {
                cell.icons = self.allBoards[indexPath.item];
                cell.title = @"Folder";
            }
            
        } else {
            cell.title = @"Test";
            cell.icons = nil;
            [cell.iconImageView setBackgroundColor:(UIColor *)data];
        }

        [cell setNeedsLayout];
        return cell;
    }
    
    TBCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:DequeueReusableCell forIndexPath:indexPath];
    [cell reset];
    cell.delegate = self;
    cell.editing = _springBoardView.editing;
    cell.title = @"Test";
    cell.icons = nil;
    [cell.iconImageView setBackgroundColor:(UIColor *)self.popupFolderView.dataSource[indexPath.item]];
    [cell setNeedsLayout];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:_springBoardView]) {

        id data = self.allBoards[indexPath.item];
        if ([data isKindOfClass:[NSMutableArray class]]) {
            _popupFolderView.hidden = NO;
            _popupFolderView.dataSource = data;
            _popupFolderView.dataSourceItemPath = indexPath;
            
            [_popupFolderView.collectionView reloadData];
        }
    }
}

#pragma mark - Delegate Cell
- (void)deleteButtonClickedInCollectionViewCell:(TBCollectionViewCell *)deletedCell
{
    NSIndexPath * gridViewCellIndexPath = [_springBoardView indexPathForCell:deletedCell];
    
    if (gridViewCellIndexPath) {
        [self.allBoards removeObjectAtIndex:gridViewCellIndexPath.item];
        [_springBoardView deleteItemsAtIndexPaths:@[gridViewCellIndexPath]];
    } else {
        gridViewCellIndexPath = [_popupFolderView.collectionView indexPathForCell:deletedCell];
        if (gridViewCellIndexPath) {

            [_popupFolderView.dataSource removeObjectAtIndex:gridViewCellIndexPath.item];
            [_popupFolderView.collectionView deleteItemsAtIndexPaths:@[gridViewCellIndexPath]];
            
            if (_popupFolderView.dataSource.count > 0) {
                [_springBoardView reloadItemsAtIndexPaths:@[_popupFolderView.dataSourceItemPath]];
            } else {
                [self.allBoards removeObjectAtIndex:_popupFolderView.dataSourceItemPath.item];
                [_springBoardView deleteItemsAtIndexPaths:@[_popupFolderView.dataSourceItemPath]];
            }
        }
    }
}

#pragma mark - 
#pragma mark FlowLayoutDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemFromIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView willMoveItemFromIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath
{
    if ([collectionView isEqual:_springBoardView]) {
        id data = self.allBoards[fromIndexPath.item];
        [self.allBoards removeObjectAtIndex:fromIndexPath.item];
        [self.allBoards insertObject:data atIndex:toIndexPath.item];
    } else {
        id data = _popupFolderView.dataSource[fromIndexPath.item];
        [_popupFolderView.dataSource removeObjectAtIndex:fromIndexPath.item];
        [_popupFolderView.dataSource insertObject:data atIndex:toIndexPath.item];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didMoveItemFromIndexPath:(NSIndexPath *)fromIndexPath intoIndexPath:(NSIndexPath *)intoIndexPath
{
    id data = [self.allBoards objectAtIndex:intoIndexPath.item];
    if ([data isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = (NSMutableArray *)data;
        UIColor *originColor = self.allBoards[fromIndexPath.item];
        [array addObject:originColor];
        
        [self.allBoards replaceObjectAtIndex:intoIndexPath.item withObject:array];
    } else {
        NSMutableArray *array = [NSMutableArray new];
        [array addObject:self.allBoards[fromIndexPath.item]];
        [array addObject:self.allBoards[intoIndexPath.item]];
        
        [self.allBoards replaceObjectAtIndex:intoIndexPath.item withObject:array];
    }
    [_springBoardView reloadItemsAtIndexPaths:@[intoIndexPath]];
    [self.allBoards removeObjectAtIndex:fromIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView willMoveItemAtIndexPathOutofEdge:(NSIndexPath *)indexPath
{
    id data = [_popupFolderView.dataSource objectAtIndex:indexPath.item];
    [_popupFolderView.dataSource removeObjectAtIndex:indexPath.item];
    [_popupFolderView.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    [_popupFolderView setHidden:YES];
    [_popupFolderView.nameField resignFirstResponder];
    
    [_springBoardView reloadItemsAtIndexPaths:@[_popupFolderView.dataSourceItemPath]];
    NSInteger index = self.allBoards.count;
    [self.allBoards insertObject:data atIndex:index];
    [_springBoardView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(self.allBoards.count-1) inSection:0]]];
}

#pragma mark -
#pragma TBPopupFolderViewDelegate
- (void)folderNameChanged:(NSString *)name indexPath:(NSIndexPath *)indexPath
{
    TBCollectionViewCell *folderCell = (TBCollectionViewCell *)[_springBoardView cellForItemAtIndexPath:indexPath];
    if (folderCell) {
        folderCell.title = name;
    }
}

@end
