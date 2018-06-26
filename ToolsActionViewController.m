//
//  ToolsActionViewController.m
//  Dee Count
//
//  Created by David G Shrock on 8/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
// parts copied from v1 ActionMenuController_iPad

#import "ToolsActionViewController.h"
#import "AppController.h"


typedef enum ToolSelection : NSUInteger {
    ToolShowZeroSelection, ToolCountManualSelection, ToolDeleteItemsSelection, ToolDeleteZeroCountsSelection, ToolRestartCountSelection, ToolClearAll, ToolCountCompareAid, ToolShowQRSearchPref, ToolNoTapScanPref, ToolShowNegatePref
}ToolSelection;

@interface ToolsActionViewController () {
    NSArray *sectionTitles;
}

@end

@implementation ToolsActionViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        sectionTitles = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Help", @"Help"),
                         NSLocalizedString(@"Counts and Items", @"Counts and Items"), NSLocalizedString(@"Preferences", @"Preferences"), nil];
        self.preferredContentSize = CGSizeMake(350.0f, 580.0f);
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        sectionTitles = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Help", @"Help"),
                         NSLocalizedString(@"Counts and Items", @"Counts and Items"), NSLocalizedString(@"Preferences", @"Preferences"), nil];
        self.preferredContentSize = CGSizeMake(350.0f, 580.0f);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"Tools", @"Tools")];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.tableView setRowHeight:64.0f];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

#pragma mark - Table view data source


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [sectionTitles objectAtIndex:section];
}

/**
 * hide index
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return sectionTitles;
}
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (section == 100) {
        return 1;
    }
    else if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        return 4;
    }
    else if (section == 2) {
        if (self.scanCodeIsAvailable) {
            return 3;
        }
        return 1;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 100) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 290.0f, 24.0f)];
        label.text = NSLocalizedString(@"Display items with zero-count in the Totals", @"Display items with zero-count in the Totals");
        UIView *footerView = [[UIView alloc] initWithFrame:label.frame];
        [footerView addSubview:label];
        return footerView;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    // Configure the cell...
    
    NSString *title = nil;
    ToolSelection selected = [self toolSelectionForIndexPath:indexPath];
    UISwitch *zeroSwitch;
    UIImage *iconImage = nil;
    UISwitch *switchView = nil;
    
    switch (selected) {
        case ToolShowZeroSelection:
            title = NSLocalizedString(@"Show Zero-counts in Totals", @"Show Zero-counts in Totals");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            zeroSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [cell setAccessoryView:zeroSwitch];
            [zeroSwitch setOn:[AppController sharedAppController].showZeroCounts animated:NO];
            [zeroSwitch addTarget:self action:@selector(zeroSwitchChanged:) forControlEvents:UIControlEventValueChanged];

            break;
        case ToolRestartCountSelection:
            title = NSLocalizedString(@"Reset Counts", @"Reset Counts");
            iconImage = [UIImage imageNamed:@"restartCounts.png"];
            break;
        case ToolDeleteItemsSelection:
            title = NSLocalizedString(@"Delete ALL Items", @"Delete ALL Items");
            iconImage = [UIImage imageNamed:@"deleteItemsAll.png"];
            break;
        case ToolDeleteZeroCountsSelection:
            title = NSLocalizedString(@"Delete Zero-count Items", @"Delete Zero-count Items");
            iconImage = [UIImage imageNamed:@"deleteItemsZero.png"];
            break;
        case ToolCountManualSelection:
            title = NSLocalizedString(@"Online Manual", @"Online Manual");
            iconImage = [UIImage imageNamed:@"manual.png"];
            break;
        case ToolClearAll:
            title = NSLocalizedString(@"Clear All and Restart", @"Clear All and Restart");
            iconImage = [UIImage imageNamed:@"clearAll.png"];
            break;
        case ToolCountCompareAid:
            title = NSLocalizedString(@"Compare Counts", @"Compare Counts");
            iconImage = [UIImage imageNamed:@"CompareCountsHelpIcon.png"];
            break;
        case ToolShowNegatePref:
            title = NSLocalizedString(@"Show +/- Toggle", @"Show +/- Toggle");
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            switchView.on = [AppController sharedAppController].showNegateToggle;
            [switchView addTarget:self action:@selector(negateToggleSwitchedChanged:) forControlEvents:UIControlEventValueChanged];

            break;
        case ToolNoTapScanPref:
            title = NSLocalizedString(@"NoTap Preference", @"auto-scan bar code (no tap)");
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            switchView.on = [AppController sharedAppController].noTapScanning;
            [switchView addTarget:self action:@selector(noTapScanningSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
        case ToolShowQRSearchPref:
            title = NSLocalizedString(@"Show QR location search", @"Show QR location search button");
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            switchView.on = [AppController sharedAppController].showQRFinder;
            [switchView addTarget:self action:@selector(showQRPrefSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
        default:
            break;
    }
    cell.textLabel.text = title;
    cell.imageView.image = iconImage;
    cell.accessoryView = switchView;
    
    return cell;
}

- (void)tableView:(UITableView *)itemsListTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ToolSelection selected = [self toolSelectionForIndexPath:indexPath];
    UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet

    
    if (selected == ToolRestartCountSelection) {

        UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ResetCountsTitle", @"Reset Counts")
                                                            message:NSLocalizedString(@"ResetCountsMsg", @"Are you sure you want to reset all counts to zero?")
                                                    preferredStyle:UIAlertControllerStyleAlert];
        weakAlert = alertSheet;
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.toolsActionDelegate resetCounts];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertSheet addAction:cancelAction];
        [alertSheet addAction:confirmAction];
        
        [self presentViewController:alertSheet animated:YES completion:nil];
    }
    else if (selected == ToolClearAll) {
        
        UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ClearAllTitle", @"Clear All")
                                                                            message:NSLocalizedString(@"ClearAllMsg", @"Are you sure you want to remove all (locations and items) and start over?")
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        weakAlert = alertSheet;
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.toolsActionDelegate restartAll];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertSheet addAction:cancelAction];
        [alertSheet addAction:confirmAction];
        
        [self presentViewController:alertSheet animated:YES completion:nil];
        
    }
    else if (selected == ToolDeleteItemsSelection) {
        UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ClearItemsTitle", @"Clear Items")
                                                            message:NSLocalizedString(@"ClearItemsMsg", @"Are you sure you want to remove ALL items, counts, and inventory details?")
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        weakAlert = alertSheet;
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.toolsActionDelegate clearAllItems];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertSheet addAction:cancelAction];
        [alertSheet addAction:confirmAction];
        
        [self presentViewController:alertSheet animated:YES completion:nil];
        
    }
    else if (selected == ToolDeleteZeroCountsSelection) {

        UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ClearZerosTitle", @"Clear Items with zero count")
                                                                            message:NSLocalizedString(@"ClearZerosMsg", @"Are you sure you want to remove items without counts including inventory details? (Your items with at least 1 count will remain.)")
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        
        weakAlert = alertSheet;
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.toolsActionDelegate clearZeroCountItems];
            [weakAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertSheet addAction:cancelAction];
        [alertSheet addAction:confirmAction];
        
        [self presentViewController:alertSheet animated:YES completion:nil];
    }
    else if (selected == ToolCountCompareAid) {
        [self.toolsActionDelegate showCompareCountHelp];
    }
    else if (selected == ToolCountManualSelection) {
            [self linkToManual];
    }

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - methods

- (void)negateToggleSwitchedChanged:(UISwitch *)sender
{
    [[AppController sharedAppController] updateShowNegateToggle:sender.on];
}

- (void)noTapScanningSwitchChanged:(UISwitch *)sender
{
    [[AppController sharedAppController] updateNoTapScanning:sender.on];
}

- (void)showQRPrefSwitchChanged:(UISwitch *)sender
{
    [[AppController sharedAppController] updateShowQRFinder:sender.on];
}

- (ToolSelection)toolSelectionForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 100) {
        return ToolShowZeroSelection;
    }
    else if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return ToolCountCompareAid;
        }
        return ToolCountManualSelection;
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            return ToolRestartCountSelection;
        }
        else if (indexPath.row == 1) {
            return ToolDeleteItemsSelection;
        }
        else if (indexPath.row == 2) {
            return ToolDeleteZeroCountsSelection;
        }
        return ToolClearAll;
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            return ToolShowNegatePref;
        }
        else if (indexPath.row == 1) {
            return ToolNoTapScanPref;
        }
        return ToolShowQRSearchPref;
    }
    return ToolCountManualSelection;
}

- (void)zeroSwitchChanged:(UISwitch *)sender
{
    [[AppController sharedAppController] updateShowZeroToUserDefaultsForEnabled:sender.on];
}

- (void)linkToManual
{
    NSURL *url = [NSURL URLWithString:@"http://www.scribd.com/doc/63888292/Dee-Count-Manual"];
    
    if (![[UIApplication sharedApplication] openURL:url])
        
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
}

@end
