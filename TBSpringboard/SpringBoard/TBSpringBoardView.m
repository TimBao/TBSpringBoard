//
//  TBSpringBoardView.m
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import "TBSpringBoardView.h"
#import "TBCollectionViewCell.h"

@implementation TBSpringBoardView

@synthesize editing = _editing;
- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    for (UICollectionViewCell * cell in self.visibleCells) {
        TBCollectionViewCell * gridViewCell = (TBCollectionViewCell *)cell;
        gridViewCell.editing = editing;
    }
}

- (BOOL)editing
{
    return _editing;
}

@end
