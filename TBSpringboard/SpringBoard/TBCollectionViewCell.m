//
//  TBCollectionViewCell.m
//  TBSpringboard
//
//  Created by baotim on 16/1/5.
//  Copyright © 2016年 tbao. All rights reserved.
//

#import "TBCollectionViewCell.h"
#import "Masonry.h"

#define WIDTH_IMAGE_IN_FOLDER ((40-15)/2.0)

@implementation TBCollectionViewCell
{
    UIButton *_deleteButton;
    UILabel  *_titleLabel;
}

@synthesize icons = _icons;
- (NSMutableArray *)icons
{
    if (!_icons) {
        _icons = [NSMutableArray new];
    }
    return _icons;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        [self setupEvents];
    }
    return self;
}

- (void)setup
{
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.layer.cornerRadius = 2;
    self.iconImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.iconImageView];
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DELETE_ICON_CORNER_RADIUS);
        make.left.equalTo(self.contentView).offset(DELETE_ICON_CORNER_RADIUS);
        make.right.equalTo(self.contentView).offset(-DELETE_ICON_CORNER_RADIUS);
        make.height.equalTo(self.iconImageView.mas_width);
    }];
    
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_deleteButton setImage:[UIImage imageNamed:@"delete_btn"] forState:UIControlStateNormal];
    [self.contentView addSubview:_deleteButton];
    _deleteButton.hidden = YES;
    [_deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(@(self.contentView.frame.size.width-DELETE_ICON_CORNER_RADIUS*2));
        make.width.equalTo(@(DELETE_ICON_CORNER_RADIUS*2));
        make.height.equalTo(@(DELETE_ICON_CORNER_RADIUS*2));
    }];
    
    _titleLabel = [[UILabel alloc]init];
    _titleLabel.text = @"";
    _titleLabel.font = [UIFont systemFontOfSize:12];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconImageView.mas_bottom).offset(5);
        make.centerX.equalTo(self.iconImageView);
        make.height.equalTo(@15);
        make.width.equalTo(self.contentView);
    }];
}

- (void)reset
{
    self.iconImageView.image = nil;
    self.iconImageView.backgroundColor = [UIColor clearColor];
    _deleteButton.hidden = YES;
    _titleLabel.text = @"";
    [_icons removeAllObjects];
}

- (void)setupEvents
{
    [_deleteButton addTarget:self action:@selector(deleteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    self.iconImageView.userInteractionEnabled = YES;
}

- (void)deleteButtonClicked:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(deleteButtonClickedInCollectionViewCell:)]) {
        [self.delegate deleteButtonClickedInCollectionViewCell:self];
    }
}

- (BOOL)editing
{
    return !_deleteButton.hidden;
}

- (void)setEditing:(BOOL)editing
{
    _deleteButton.hidden = !editing;
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
}

- (NSString *)title
{
    return _titleLabel.text;
}

- (void)setIcons:(NSMutableArray *)icons
{
    if (!icons || icons.count == 0) {
        [self.iconImageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        return;
    } else {
        self.iconImageView.image = [UIImage imageNamed:@"folder_bg"];
        [self.iconImageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (int i = 0; i < icons.count; ++i) {
            if (i < 4) {
                UIColor *color = icons[i];
                UIImageView *appIcon = [UIImageView new];
                [self.iconImageView addSubview:appIcon];
                [appIcon mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.width.equalTo(@(WIDTH_IMAGE_IN_FOLDER));
                    make.height.equalTo(@(WIDTH_IMAGE_IN_FOLDER));
                    make.left.equalTo([NSNumber numberWithFloat:(i%2==0 ? 5 : WIDTH_IMAGE_IN_FOLDER + 10)]);
                    make.top.equalTo([NSNumber numberWithFloat:(i<2 ? 5 : WIDTH_IMAGE_IN_FOLDER + 10)]);
                }];
                [appIcon setBackgroundColor:color];
            } else {
                break;
            }
        }
    }
}

- (UIView *)snapshotView
{
    UIView * snapshotView = [[UIView alloc] init];
    
    UIView * cellSnapshotView = nil;
    
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        cellSnapshotView = [self snapshotViewAfterScreenUpdates:NO];
    }
    else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cellSnapshotView = [[UIImageView alloc]initWithImage:cellSnapshotImage];
    }
    
    snapshotView.frame = cellSnapshotView.bounds;
    
    [snapshotView addSubview:cellSnapshotView];
    
    return snapshotView;
}

@end
