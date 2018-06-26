//
//  ItemCell.m
//  DCount
//
//  Created by David Shrock on 10/24/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import "ItemCell.h"
#import "DTCountItem.h"
#import "AppController.h"

@interface ItemCell () {
    UILabel *itemUPCLabel;
    //UITextView *itemUPCText;
    UILabel *itemDescLabel;
    UILabel *countLabel;
    UIImageView *itemImageView;
    //id <ItemCutDelegate> itemCutDelegate;
}

@end

@implementation ItemCell

@synthesize cellActionDelegate, isTotalType;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
		[self setBackgroundColor:[UIColor whiteColor]];
		countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[[self contentView] addSubview:countLabel];
		
		itemUPCLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[[self contentView] addSubview:itemUPCLabel];
        //itemUPCText = [[UITextView alloc] initWithFrame:CGRectZero];
        //[itemUPCText setScrollEnabled:NO];
        //[itemUPCText setEditable:NO];
        //[itemUPCText setBorderStyle:UITextBorderStyleNone];
        //[[self contentView] addSubview:itemUPCText];
		
		itemDescLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[[self contentView] addSubview:itemDescLabel];
		
		itemImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[[self contentView] addSubview:itemImageView];
		
		[itemImageView setContentMode:UIViewContentModeScaleAspectFit];
       
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [[AppController sharedAppController] barColor];
        self.selectedBackgroundView = v;
        
        [itemUPCLabel setTextColor:[UIColor blackColor]];
        [itemUPCLabel setHighlightedTextColor:[UIColor whiteColor]];
        [itemDescLabel setTextColor:[UIColor darkGrayColor]];
        [itemDescLabel setHighlightedTextColor:[UIColor lightGrayColor]];
        
        [countLabel setTextColor:[UIColor blackColor]];
        [countLabel setHighlightedTextColor:[UIColor whiteColor]];
        
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
	
	float inset = 3.2;
	CGRect bounds = [[self contentView] bounds];
	float h = bounds.size.height;
	float w = bounds.size.width;
	float valueWidth = 40.0;
	float valueHeight = h - inset * 2.0;
	
	// make rectangle inset and nearly square
	// using height of contentView
	CGRect innerFrame = CGRectMake(inset, inset - 1.2f, h, valueHeight);
	[itemImageView setFrame:innerFrame];
	
	// move rectangle over and resize for namelabel
	innerFrame.origin.x += innerFrame.size.width + inset;
	innerFrame.size.width = w - (h + valueWidth * 2.30 + inset * 4);
	innerFrame.size.height = valueHeight * 0.650;
	[itemUPCLabel setFrame:innerFrame];
    //[itemUPCText setFrame:innerFrame];
	
	// move down for desc
	innerFrame.origin.y += innerFrame.size.height - 1.2f;
    innerFrame.size.height = valueHeight * 0.40;
	[itemDescLabel setFrame:innerFrame];
	
	// move that rectangle over again and resize for valuelabel
	innerFrame.origin.x += innerFrame.size.width - 6.0;
	innerFrame.origin.y = inset;
	innerFrame.size.width = valueWidth * 2.5 + inset + 0.2;
	innerFrame.size.height = valueHeight;
	[countLabel setFrame:innerFrame];
    [countLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self updateInterfaceForTypeSize];
    
}

- (void)dealloc
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    
    [super setSelected:selected animated:animated];
    
    if (selected)
    {
        //[bgView setHidden:NO];
        [self setBackgroundColor:[AppController sharedAppController].barColor];
        
        
    }
    else
    {
        //[bgView setHidden:YES];
        [self setBackgroundColor:[AppController sharedAppController].barLightColor];

    }
    
}

- (void)setCategoryItem:(DTCountCategory *)category isChecked:(BOOL)checked
{
    NSArray *items = [category valueForKey:@"items"];
    NSUInteger count = items.count;
    
    [self setUniversalLabel:[NSString stringWithFormat:@"%@", [category valueForKey:@"label"]] withCount:count withTotalCount:-1 withDescription:@"" isChecked:checked];
}

- (void)setUniversalLabel:(NSString *)label withCount:(NSInteger)count withTotalCount:(NSInteger)totalCnt withDescription:(NSString *)desc isChecked:(BOOL)checked
{
    NSString *countStr = [[AppController sharedAppController] formatNumber:count];
    
    [itemUPCLabel setText:label];
    if (desc.length > 0) {
        [itemDescLabel setText:desc];
    }
    else {
        [itemDescLabel setText:@""];
    }
    
    if (checked) {
        UIImageView *checkedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
        [self setAccessoryView:checkedView];
    }
    else if (isTotalType) {
        [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else {
        [self setAccessoryType:UITableViewCellAccessoryNone];
        [self setAccessoryView:nil];
    }
    if (totalCnt >= 0) {
        NSString *totalCountStr = [[AppController sharedAppController] formatNumber:totalCnt];
        [countLabel setText:[NSString stringWithFormat:@"%@ / %@", countStr, totalCountStr]];
        if (totalCnt != count) {
            countLabel.textColor = [UIColor redColor];
            countLabel.highlightedTextColor = [UIColor redColor];
        }
        else {
            [countLabel setTextColor:[UIColor blackColor]];
            [countLabel setHighlightedTextColor:[UIColor whiteColor]];
        }
    }
    else {
        [countLabel setText:[NSString stringWithFormat:@"%@", countStr]];
        [countLabel setTextColor:[UIColor blackColor]];
        [countLabel setHighlightedTextColor:[UIColor whiteColor]];
    }
    
    
}


- (void)setItem:(DTCountItem *)item setCount:(NSInteger)count setTotalCount:(NSInteger)totalCnt
{
	NSString *desc = [item valueForKey:@"desc"];
    
    NSString *label = [NSString stringWithFormat:@"%@", [item valueForKey:@"label"]];
    
    [self setUniversalLabel:label withCount:count withTotalCount:totalCnt withDescription:desc isChecked:NO];
}

- (NSString *)countText
{
	NSRange range = [[countLabel text] rangeOfString:@" / "];
	if (range.location != NSNotFound) {
		return [countLabel text];
	}
	return [[countLabel text] substringToIndex:range.location];
}

#pragma mark menuitem support

- (void)showCopyMenuWithNegate:(BOOL)withNegateIncrement
{
    [self becomeFirstResponder];
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    NSString *incStr = @"++";
    if (withNegateIncrement) {
        incStr = @"+-";
    }
    UIMenuItem *incMenuItem = [[UIMenuItem alloc] initWithTitle:incStr action:@selector(increment:)];
    UIMenuItem *detMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Details", @"Details") action:@selector(detailSelect:)];
    [theMenu setMenuItems: @[detMenuItem, incMenuItem]];
    [theMenu update];
    CGRect rect = CGRectMake([itemUPCLabel frame].origin.x, [itemUPCLabel frame].origin.y + 5.0f, [itemUPCLabel frame].size.width *0.5, [itemUPCLabel frame].size.height);
    [theMenu setTargetRect:rect inView:self];
    [theMenu setMenuVisible:YES animated:YES];
}

- (void)copy:(id)sender 
{
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    [gpBoard setValue:[itemUPCLabel text] forPasteboardType:@"public.utf8-plain-text"];
}

// increment item on menu action
- (void)increment:(id)sender
{
    [self.cellActionDelegate selectedItemCodeToIncrement:itemUPCLabel.text];
}

- (void)detailSelect:(id)sender
{
    [self.cellActionDelegate selectedItemDetailsForLabel:itemUPCLabel.text];
}

/*
- (void)cut:(id)sender
{
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    [gpBoard setValue:[itemUPCLabel text] forPasteboardType:@"public.utf8-plain-text"];
    
}
 */

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender 
{
    if (self.isTotalType) {
        return (action == @selector(copy:));
    }
    return (action == @selector(copy:) || action == @selector(detailSelect:) || action == @selector(increment:));
}

- (BOOL)canBecomeFirstResponder 
{
    return YES;
}

- (void)updateInterfaceForTypeSize
{
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *fontSub = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    itemUPCLabel.font = font;
    if (isTotalType) {
        countLabel.font = fontSub;
    }
    else {
        countLabel.font = font;
    }
    
    itemDescLabel.font = fontSub;
}


@end
