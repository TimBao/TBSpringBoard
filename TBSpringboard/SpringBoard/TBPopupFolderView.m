//
//  TBPopupFolderView.m
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import "TBPopupFolderView.h"
#import "TBCollectionViewCell.h"
#import "TBSpringBoardView.h"
#import "Masonry.h"

@interface TBPopupFolderView() <UITextFieldDelegate, UIGestureRecognizerDelegate>

@end

@implementation TBPopupFolderView
{
    UIView *_bgView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nameField = [[UITextField alloc] init];
        _nameField.delegate = self;
        _nameField.text = @"My Folder";
        _nameField.font = [UIFont systemFontOfSize:20];
        _nameField.textAlignment = NSTextAlignmentCenter;
        _nameField.backgroundColor = [UIColor clearColor];
        [self addSubview:_nameField];
        [_nameField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(150);
            make.left.equalTo(self).offset(50);
            make.right.equalTo(self).offset(-50);
            make.height.equalTo(@25);
        }];
        
        UICollectionViewFlowLayout *_gridViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
        _gridViewFlowLayout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
        _gridViewFlowLayout.minimumLineSpacing = 35;
        _gridViewFlowLayout.itemSize = CGSizeMake(60, 80);
        
        _collectionView = [[TBSpringBoardView alloc] initWithFrame:self.bounds collectionViewLayout:_gridViewFlowLayout];
        _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _collectionView.scrollEnabled = YES;
        _collectionView.layer.masksToBounds = YES;
        _collectionView.layer.cornerRadius = 5;
        _collectionView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_collectionView];
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_nameField.mas_bottom);
            make.left.equalTo(self).offset(50);
            make.right.equalTo(self).offset(-50);
            make.bottom.equalTo(self).offset(-150);
        }];
        [_collectionView registerClass:[TBCollectionViewCell class] forCellWithReuseIdentifier:DequeueReusableCell];
        
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor blackColor];
        _bgView.alpha = 0.1f;
        _bgView.userInteractionEnabled = YES;
        UIGestureRecognizer *backgroundTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap:)];
        [_bgView addGestureRecognizer:backgroundTap];
        [self addSubview:_bgView];
        [self sendSubviewToBack:_bgView];
        [_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
            make.width.equalTo(self);
            make.height.equalTo(self);
        }];
        
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];
        [self addGestureRecognizer:tap];
        tap.delegate = self;
    }
    return self;
}

- (void)onBackgroundTap:(id)sender
{
    [_nameField resignFirstResponder];
    self.hidden = YES;
}

- (void)setDataSource:(NSMutableArray *)dataSource
{
    _dataSource = dataSource;
    [_collectionView reloadData];
}

#pragma mark - Gesture Action
- (void)dismissKeyboard
{
    [_nameField resignFirstResponder];
}

#pragma mark - TextFiledDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(folderNameChanged:indexPath:)]) {
        [self.delegate folderNameChanged:textField.text indexPath:self.dataSourceItemPath];
    }
}


@end
