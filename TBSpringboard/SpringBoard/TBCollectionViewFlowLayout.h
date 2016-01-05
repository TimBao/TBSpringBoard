//
//  TBCollectionViewHelper.h
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TBCollectionViewFlowLayoutDataSource <UICollectionViewDataSource>

@optional
/**
 *  Can indexPath in collectionView be moved.
 *
 *  @param collectionView desktop or folder
 *  @param indexPath
 */
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Can move fromIndexPath in collectionView to the destination indexPath.
 *
 *  @param collectionView  desktop or folder
 *  @param fromIndexPath   source IndexPath
 *  @param toIndexPath     destination IndexPath
 */
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemFromIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath;

/**
 *  You can do some animation or preview the move result.
 *
 *  @param collectionView desktop or folder
 *  @param fromIndexPath   source IndexPath
 *  @param toIndexPath     destination IndexPath
 */
- (void)collectionView:(UICollectionView *)collectionView willMoveItemFromIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath;

/**
 *  Move fromIndexPath item into another item or folder which indexPath is intoIndexPath.
 *
 *  @param collectionView desktop
 *  @param fromIndexPath
 *  @param intoIndexPath
 */
- (void)collectionView:(UICollectionView *)collectionView didMoveItemFromIndexPath:(NSIndexPath *)fromIndexPath intoIndexPath:(NSIndexPath *)intoIndexPath;

/**
 *  Will move item out of folder view.
 *
 *  @param collectionView folder view
 *  @param indexPath      indexPath in forlder view.
 */
- (void)collectionView:(UICollectionView *)collectionView willMoveItemAtIndexPathOutofEdge:(NSIndexPath *)indexPath;


@end

@interface TBCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) UICollectionView *desktopView;
@property (nonatomic, strong) UICollectionView *folderView;

@end
