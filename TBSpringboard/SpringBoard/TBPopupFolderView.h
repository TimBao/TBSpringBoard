//
//  TBPopupFolderView.h
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* DequeueReusableCell = @"TBSpringBoardCellReuseIdentifier";

@class TBSpringBoardView;
@interface TBPopupFolderView : UIView

@property (nonatomic, strong) NSMutableArray    *dataSource;
@property (nonatomic, strong) UITextField       *nameField;
@property (nonatomic, strong) TBSpringBoardView *collectionView;
@property (nonatomic, weak  ) NSIndexPath       *dataSourceItemPath;

@end
