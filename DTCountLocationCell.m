//
//  DTCountLocationCell.m
//  Dee Count
//
//  Created by David G Shrock on 8/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1 for ARC and style

#import "DTCountLocationCell.h"
#import "DTCountLocation.h"
#import "AppController.h"

@interface DTCountLocationCell ()


//@property UIImageView *imageView;

@end

@implementation DTCountLocationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        [[self contentView] addSubview:self.nameLabel];
        
        //[[self contentView] addSubview:self.imageView];
        
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [AppController sharedAppController].barColor;
        self.selectedBackgroundView = v;

        [self updateInterfaceForTypeSize];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(updateInterfaceForTypeSize)
                   name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float inset = 5.0;
    CGRect bounds = self.contentView.bounds;
    float h = bounds.size.height;
    float w = bounds.size.width;
    float valueWidth = 40.0;
    [[self backgroundView] setFrame:bounds];
    
    // make rectangle inset and nearly square
    // using height of contentView
    CGRect innerFrame = CGRectMake(inset, inset, h, h - inset * 2.0);
    [self.imageView setFrame:innerFrame];
    
    
    // move rectangle over and resize for namelabel
    innerFrame.origin.x += innerFrame.size.width + inset;
    innerFrame.size.width = w - (h + valueWidth + inset * 4);
    [self.nameLabel setFrame:innerFrame];
    
    // move that rectangle over again and resize for valuelabel
    //innerFrame.origin.x += innerFrame.size.width + inset;
    //innerFrame.size.width = valueWidth;
    //[countLabel setFrame:innerFrame];
    
    //CALayer *l = [imageView layer];
    //[l setMasksToBounds:YES];
    //[l setCornerRadius:10.0];
    //[l setBorderWidth:0.5];
    //[l setBorderColor:col];
}

- (void)dealloc
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)setLocation:(DTCountLocation *)loc
{
    [self.nameLabel setText:[NSString stringWithFormat:@"%@", [loc valueForKey:@"label"]]];
    
    [self.imageView setImage:loc.thumbnail];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    if (selected)
    {
        //[bgView setHidden:NO];
        [self setBackgroundColor:[AppController sharedAppController].barColor];
        [self.nameLabel setTextColor:[UIColor whiteColor]];
    }
    else
    {
        //[bgView setHidden:YES];
        [self setBackgroundColor:[UIColor whiteColor]];
        [self.nameLabel setTextColor:[UIColor blackColor]];
    }
    
}

- (void)updateInterfaceForTypeSize
{
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.nameLabel.font = font;
    
}
@end
