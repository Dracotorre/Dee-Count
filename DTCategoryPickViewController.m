//
//  DTCategoryPickViewController.m
//  Dee Count
//
//  Created by David G Shrock on 9/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCategoryPickViewController.h"
#import "DTCountCategory.h"
#import "DTCountCategoryStore.h"
#import "DTCountItem.h"
#import "AppController.h"
#import "DTCountLocation.h"

@interface DTCategoryPickViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISwitch *updateAllSwitch;
@property (weak, nonatomic) IBOutlet UILabel *updateAllLabel;

@property (strong, nonatomic) NSString *catLabelStartedWith;

@end

@implementation DTCategoryPickViewController

- (instancetype)init
{
    self = [super initWithNibName:@"DTCategoryPickViewController" bundle:nil];
    if (self) {
        self.title = NSLocalizedString(@"Category", @"Category");
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.navigationItem.rightBarButtonItem.tintColor = [[AppController sharedAppController] barButtonColor];
        self.updateAllLabel.alpha = 0.0f;
        self.updateAllSwitch.alpha = 0.0f;
        self.preferredContentSize = CGSizeMake(320.0f, 480.0f);
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self init];   // forcing the plain
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setDoneButton];
    
    if (self.location) {
        self.catLabelStartedWith = [self.location valueForKey:@"defCatLabel"];
    }

    self.navigationController.navigationBar.translucent = NO;
    self.categoryTextField.alpha = 0.0f;
    self.categoryTextField.placeholder = NSLocalizedString(@"new category name", @"new category name");
    self.categoryTextField.delegate = self;
    self.updateAllLabel.text = NSLocalizedString(@"update uncategorized items", @"update uncategorized items");
    if (self.showUpdateAllOption) {
        self.updateAllLabel.alpha = 1.0f;
        self.updateAllSwitch.alpha = 1.0f;
    }
    else {
        self.updateAllLabel.alpha = 0.0f;
        self.updateAllSwitch.alpha = 0.0f;
    }
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
    [self checkCategoryLimit];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self scrollToSelectedCat];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.showUpdateAllOption && self.updateAllSwitch.on && self.location) {
        NSString *finalCatLabel = [self.location valueForKey:@"defCatLabel"];
        if (finalCatLabel.length > 0 && [finalCatLabel isEqualToString:self.catLabelStartedWith] == NO) {
          [self.delegate updateCategoryForUncategorizedItemsForLocation:self.location];
        }
    }
}

- (void)scrollToSelectedCat
{
    DTCountCategory *selectedCat = nil;
    if (self.item) {
        selectedCat = (DTCountCategory *)[self.item valueForKey:@"category"];
    }
    else if (self.location) {
        NSString *catLabel = [self.location valueForKey:@"defCatLabel"];
        if (catLabel.length > 0) {
            selectedCat = [[DTCountCategoryStore sharedStore] categoryWithLabel:catLabel];
        }
    }
    if (selectedCat) {
        NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
        int index = -1;
        for (int i = 0; i < allCats.count; ++i) {
            if (selectedCat == [allCats objectAtIndex:i]) {
                index = i;
                break;
            }
        }
        if (index >= 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

- (void)setDoneButton
{
    if (self.dismissBlock) {
        UIBarButtonItem *doneBut = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonAction:)];
        doneBut.tintColor = [[AppController sharedAppController] barButtonColor];
        self.navigationItem.leftBarButtonItem = doneBut;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)checkCategoryLimit
{
    if ([[DTCountCategoryStore sharedStore] allCategories].count > 99) {
        self.categoryTextField.enabled = NO;
        self.categoryTextField.placeholder = NSLocalizedString(@"maximum categories", @"maximum categories");
    }
    else {
        self.categoryTextField.placeholder = NSLocalizedString(@"add new category", @"add new category");
        self.categoryTextField.enabled = YES;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    
    
    CGFloat alpha = 0.0f;
    CGFloat nonEditAlpha = 0.0f;
    
    if (self.showUpdateAllOption) {
        nonEditAlpha = 1.0f;
    }
    
    if (editing) {
        alpha = 1.0f;
        nonEditAlpha = 0.0f;
        self.categoryTextField.text = @"";
        self.navigationItem.leftBarButtonItem = nil;
    }
    else {
        [self.categoryTextField resignFirstResponder];
        [self setDoneButton];
        if (self.categoryTextField.text.length > 0) {
             [self categoryTextDidEnd:nil];
         }
    }
    if (animated) {
        [UIView animateWithDuration:0.45f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.categoryTextField.alpha = alpha;
                             self.updateAllSwitch.alpha = nonEditAlpha;
                             self.updateAllLabel.alpha = nonEditAlpha;
                         }
                         completion:^(BOOL finished){
                             if (!editing) {
                                 
                             }
                             [self.tableView setEditing:editing animated:animated];
                             
                         }];
    }
    else {
        self.categoryTextField.alpha = alpha;
        self.updateAllSwitch.alpha = nonEditAlpha;
        self.updateAllLabel.alpha = nonEditAlpha;
        [self.tableView setEditing:editing animated:animated];
    }

    
}

- (void)doneButtonAction:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

#pragma mark -
#pragma mark - tableview

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
    if (indexPath.row >= allCats.count) {
        return NO;
    }
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // add extra empty for buffer
    return [[DTCountCategoryStore sharedStore] allCategories].count + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
    
    if (indexPath.row < allCats.count) {
        DTCountCategory *cat = (DTCountCategory *)[allCats objectAtIndex:indexPath.row];
        
        // use key-value coding to get label
        NSString *catLabel = [cat valueForKey:@"label"];
        cell.textLabel.text = catLabel;
        
        // checkmark the one that is currently selected
        if (self.item) {
            if (cat == self.item.category) {
                UIImageView *checkedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
                cell.accessoryView = checkedView;
            }
            else {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if (self.location) {
            NSString *locCatLabel = [self.location valueForKey:@"defCatLabel"];
            if ([locCatLabel isEqualToString:catLabel]) {
                UIImageView *checkedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
                cell.accessoryView = checkedView;
            }
            else {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    else {
        cell.textLabel.text = @"";
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if (cell.accessoryView != nil) {
        [self.tableView beginUpdates];
        if (self.item) {
            self.item = [[DTCountCategoryStore sharedStore] removeCategoryFromItem:self.item];
        }
        else if (self.location) {
            [self.location setValue:@"" forKey:@"defCatLabel"];
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else {
        UIImageView *checkedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
        cell.accessoryView = checkedView;
        
        [self.tableView beginUpdates];
        
        NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
        //DTCountCategory *oldCat = nil;
        
        DTCountCategory *cat = (DTCountCategory *)[allCats objectAtIndex:indexPath.row];
        if (self.item) {
            //oldCat = [self.item valueForKey:@"category"];
            self.item = [[DTCountCategoryStore sharedStore] itemSetCategory:cat forItem:self.item];
        }
        else if (self.location) {
            NSString *catLabel = [cat valueForKey:@"label"];
            [self.location setValue:catLabel forKey:@"defCatLabel"];
        }
        /*
         * since removing, view don't need to uncheck - animation fade takes longer
        if (oldCat != nil) {
            
            for (int i = 0; i < allCats.count; ++i) {
                DTCountCategory *cat = (DTCountCategory *)[allCats objectAtIndex:i];
                if (cat == oldCat) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                    //UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
                    //cell.accessoryType = UITableViewCellAccessoryNone;
                    [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
            }
        }
        */
        [self.tableView endUpdates];

        if (self.dismissBlock) {
            [self doneButtonAction:nil];
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
        }

    }
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        DTCountCategory *cat = [[[DTCountCategoryStore sharedStore] allCategories] objectAtIndex:indexPath.row];
        
        if (self.location) {
            NSString *catLabel = [cat valueForKey:@"label"];
            if ([self.location.defCatLabel isEqualToString:catLabel]) {
                [self.location setValue:@"" forKey:@"defCatLabel"];
            }
        }
        if ([DTCountCategoryStore sharedStore].allCategories.count <= 1) {
            // store auto-inserts a new cat to prevent empty
            [[DTCountCategoryStore sharedStore] deleteCategory:cat];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [[DTCountCategoryStore sharedStore] deleteCategory:cat];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if (self.categoryTextField.enabled == NO) {
            [self checkCategoryLimit];
        }
    }
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *filteredString = [[string componentsSeparatedByCharactersInSet:[[AppController sharedAppController] badCharacters]] componentsJoinedByString:@""];
    if ([filteredString isEqualToString:string] == NO) {
        return NO;
    }
    return YES;
}


#pragma mark -
#pragma mark - outlets

- (IBAction)categoryTextDidEnd:(id)sender
{
    if (self.categoryTextField.text.length > 0) {
        NSString *oldItemCatLabel = nil;
        
        if (self.item) {
            DTCountCategory *oldItemCat = [self.item valueForKey:@"category"];
            
            if (oldItemCat) {
                oldItemCatLabel = [oldItemCat valueForKey:@"label"];
            }
        }
        else if (self.location) {
            oldItemCatLabel = [self.location valueForKey:@"defCatLabel"];
        }
        
        int catCountBefore = (int)[[DTCountCategoryStore sharedStore] allCategories].count;
        NSString *catString = [[AppController sharedAppController] stripBadCharactersFromString:self.categoryTextField.text];
        
        catString = [catString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (catString.length > [AppController sharedAppController].maxTitleLength) {
            catString = [catString substringToIndex:[AppController sharedAppController].maxTitleLength];
        }
        if (catString.length > 0) {
            // insert and auto-pick new category
            
            // Begin update - must go before data change
            [self.tableView beginUpdates];
            
            DTCountCategory *cat = [[DTCountCategoryStore sharedStore] categoryWithLabel:catString];
            NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
            catString = [cat valueForKey:@"label"];
            if (self.item) {
                self.item = [[DTCountCategoryStore sharedStore] itemSetCategory:cat forItem:self.item];
            }
            else if (self.location) {
                [self.location setValue:catString forKey:@"defCatLabel"];
            }
            int insertedIndex = 1000;

            NSIndexPath *ipOfUpdate = nil;
            
            if ([oldItemCatLabel isEqualToString:catString] == NO) {
                for (int i = 0; i < allCats.count; ++i) {
                    DTCountCategory *curCat = (DTCountCategory *)[allCats objectAtIndex:i];
                    NSString *label = [curCat valueForKey:@"label"];
                    
                    if ([label compare:catString options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                        ipOfUpdate = [NSIndexPath indexPathForRow:i inSection:0];
                        if (allCats.count > catCountBefore) {
                            insertedIndex = i;
                            [self.tableView insertRowsAtIndexPaths:@[ipOfUpdate] withRowAnimation:UITableViewRowAnimationLeft];
                        }
                        else {
                            [self.tableView reloadRowsAtIndexPaths:@[ipOfUpdate] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    }
                    else if (oldItemCatLabel && oldItemCatLabel.length > 0) {
                        if ([label compare:oldItemCatLabel options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                            int adj = 0;
                            if (insertedIndex < i) {
                                adj = -1;
                            }
                            ipOfUpdate = [NSIndexPath indexPathForRow:i + adj inSection:0];
                            [self.tableView reloadRowsAtIndexPaths:@[ipOfUpdate] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    }
                }
            }
            
            
            [self.tableView endUpdates];
            
        }
        
    }
    [self.categoryTextField setText:@""];
    [self checkCategoryLimit];

}


@end
