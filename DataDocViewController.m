//
//  ExportDataViewController.m
//  Dee Count
//
//  Created by David G Shrock on 8/26/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DataDocViewController.h"
#import "DTCBGOperationsWorker.h"
#import "AppController.h"
#import <MobileCoreServices/MobileCoreServices.h>

typedef enum ExportImportSelection : NSUInteger {
    ExportLimitMismatchSwitch, ExportFileSelection, ExportOpenInSelection, ExportEmailSelection, ExportPrintSelection, ImportFileSelection, QRCodeSelection
}ExportImportSelection;

@interface DataDocViewController () {
    ExportImportSelection chosenSelection;
    NSURL *exportedFileUrl;
    BOOL exportMismatchOnly;
    BOOL printSupported;
    BOOL pEnabled;
    SaveOpFileStyle exportFileStyle;
    int limitSelectionType;
}

@property (nonatomic, strong) DTCBGOperationsWorker *pendingSaveToFileOps;

@end

@implementation DataDocViewController

@synthesize showMismatchSwitch;

- (instancetype)initForImportOnlyWithGuided:(BOOL)isGuided
{
    if (isGuided) {
        return [self initPrivate:3];
    }
    return [self initPrivate:2];
}

- (instancetype)initForExportOnly
{
    return [self initPrivate:1];
}

- (instancetype)init
{
    return [self initPrivate:0];
}

- (instancetype)initPrivate:(int)limitPick
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        limitSelectionType = limitPick;
        printSupported = NO;
        self.exportFileName = @"dCount";
        self.headerText = @"";
        if (limitSelectionType == 3) {
            self.preferredContentSize = CGSizeMake(360.0f, 480.0f);
        }
        else if (limitSelectionType > 0) {
            self.preferredContentSize = CGSizeMake(320.0f, 312.0f);
        }
         else {
            self.preferredContentSize = CGSizeMake(320.0f, 392.0f);
        }
        exportFileStyle = SaveOpDCZStyle;
        pEnabled = YES;
        
        // TODO: printing disabled until testing and format updated
        
        if ([UIPrintInteractionController isPrintingAvailable]) {
            printSupported = YES;
        }
         
        self.navigationItem.title = NSLocalizedString(@"Send", @"Send");
        
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.needsDoneButton) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    }
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.tableView setRowHeight:64.0f];
    [self.tableView reloadData];
    
    // do we need to jump ahead?
    if (limitSelectionType > 1) {
        [self enableAll:NO];
        [self importFile];
    }
}

- (void)viewDidLayoutSubviews
{
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.backBarButtonItem.tintColor = [[AppController sharedAppController] barButtonColor];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (limitSelectionType == 1) {
        if (showMismatchSwitch) {
            return 3;
        }
        return 2;
    }
    else if (limitSelectionType > 1) {
        return 1;
    }
    NSInteger result = 2;
    if (showMismatchSwitch) {
        result++;
    }
    if (self.includeEmailExport) {
        result++;
    }
    if (printSupported) {
        result++;
    }
    if (self.includeImport) {
        result++;
    }
    if (self.locationName.length > 0) {
        // for QR sharing
        result++;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExportCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ExportCell"];
    }
    // Configure the cell...
    NSString *title = @"";
    UIImage *iconImage = nil;
    UIImage *defImage = [UIImage imageNamed:@"exportCloudIcon.png"];
    ExportImportSelection selected = [self selectionForIndexPath:indexPath];
    UISwitch *mismatchSwitch;
    UIImage *qrImage = [self createQRImageForString:self.locationName withColor:[AppController sharedAppController].barButtonColor forSize:defImage.size includeTextInImage:NO];
    
    switch (selected) {
        case ExportLimitMismatchSwitch:
            title = NSLocalizedString(@"Limit to count mismatch", @"Limit to count mismatch");
        
            // Font??
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            mismatchSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [cell setAccessoryView:mismatchSwitch];
            [mismatchSwitch addTarget:self action:@selector(mismatchSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        case ExportFileSelection:
            title = NSLocalizedString(@"Export to storage", @"Export to storage");
            iconImage = [UIImage imageNamed:@"exportCloudIcon.png"];
            break;
        case ExportOpenInSelection:
            title = NSLocalizedString(@"Open In Another App", @"Open In Another App");
            iconImage = [UIImage imageNamed:@"openInIcon.png"];
            break;
        case ExportPrintSelection:
            title = NSLocalizedString(@"Print", @"Print");
            iconImage = [UIImage imageNamed:@"printerIcon.png"];
            break;
        case ExportEmailSelection:
            title = NSLocalizedString(@"E-mail", @"E-mail");
            iconImage = [UIImage imageNamed:@"mailIcon.png"];
            break;
        case ImportFileSelection:
            title = NSLocalizedString(@"Import count comparison", @"Import count comparison");
            iconImage = [UIImage imageNamed:@"importCloudIcon.png"];
            break;
        case QRCodeSelection:
            title = NSLocalizedString(@"QR code title", @"QR code title");
            iconImage = qrImage;
            //iconImage = [UIImage imageWithCIImage:qrImage];
            //UIGraphicsBeginImageContext(CGSizeMake(defImage.size.width, defImage.size.width));
            //[iconImage drawInRect:CGRectMake(0, 0, defImage.size.width, defImage.size.width)];
            
            //iconImage = UIGraphicsGetImageFromCurrentImageContext();
            //UIGraphicsEndImageContext();
            break;
        default:
            break;
    }
    cell.textLabel.text = title;
    cell.imageView.image = iconImage;
    
    
    return cell;
}

- (void)tableView:(UITableView *)itemsListTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (pEnabled) {
        [self enableAll:NO];
        chosenSelection = [self selectionForIndexPath:indexPath];
        
        if (chosenSelection == ImportFileSelection) {
            [self importFile];
        }
        else if (chosenSelection == ExportPrintSelection) {
            DocFormatPickViewController *docFormatPicker = [[DocFormatPickViewController alloc] init];
            docFormatPicker.delegate = self;
            docFormatPicker.hidden = YES;
            
            [self.navigationController pushViewController:docFormatPicker animated:NO];
            
            [self prepPrint];
        }
        else if (chosenSelection == QRCodeSelection) {
            [self exportQRCode];
        }
        else if (limitSelectionType == 1) {
            exportFileStyle = SaveOpDCZStyle;
            [self saveExportFile];
        }
        else {
            DocFormatPickViewController *docFormatPicker = [[DocFormatPickViewController alloc] init];
            docFormatPicker.delegate = self;
            [self.navigationController pushViewController:docFormatPicker animated:YES];
        }
    }
}

- (NSString *)tableView:(UITableView *)itemsListTableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return self.headerText;
    }
    return @"";
}

#pragma mark - UIDocument menu delegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker
{
    [self enableAll:YES];
    BOOL isImport = (chosenSelection == ImportFileSelection);
    
    [self.delegate dataDocumentMenu:documentMenu didPickDocumentPicker:documentPicker forImport:isImport];
}

- (void)documentMenuWasCancelled:(UIDocumentMenuViewController *)documentMenu
{
    [self enableAll:YES];
}



#pragma mark - SaveOutputfFilesOperation delegate

- (void)doneSavingOutputDocsForProccess:(SaveOutputFilesOperation *)process
{
    
    NSString *fullFileName = process.fullFileNameWithDirectory;
    
    [self.pendingSaveToFileOps.bgOpInProgress removeObjectForKey:process.shortFileName];

    exportedFileUrl = [NSURL fileURLWithPath:fullFileName];
    
    if (chosenSelection == ExportFileSelection) {
        [self.navigationController popViewControllerAnimated:NO];
        
        UIDocumentMenuViewController *docMenuController = [[UIDocumentMenuViewController alloc] initWithURL:exportedFileUrl inMode:UIDocumentPickerModeExportToService];
        docMenuController.delegate = self;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:docMenuController animated:YES completion:nil];
        });
        
    }
    else if (chosenSelection == ExportOpenInSelection) {
        [self enableAll:YES];
        [self.delegate dataDocOpenInWithURL:exportedFileUrl];
    }
    else if (chosenSelection == ExportEmailSelection) {
        [self enableAll:YES];
        [self.delegate dataDocSendMailWithFileURL:exportedFileUrl forFileName:process.shortFileName];
        
    }
}

#pragma mark - PreparePrintOutput delegate

- (void)donePreparePrintForProccess:(PreparePrintOutputOperation *)process
{
    [self enableAll:YES];
    [self.pendingSaveToFileOps.bgOpInProgress removeObjectForKey:process.key];
    
    [self.delegate printRequestForOutputText:process.resultOutputText];
}

#pragma mark - DocFormat delegate

- (void)canceledPicker
{
    [self enableAll:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pickedFormatDCZ
{
    exportFileStyle = SaveOpDCZStyle;

    [self saveExportFile];
}

- (void)pickedFormatCSV
{
    exportFileStyle = SaveOpCSVStyle;

    [self saveExportFile];
}


#pragma mark - methods

- (void)done:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

- (void)enableAll:(BOOL)enabled
{
    pEnabled = enabled;
    [self.navigationItem.leftBarButtonItem setEnabled:enabled];
}

- (ExportImportSelection)selectionForIndexPath:(NSIndexPath *)indexPath
{
    if (limitSelectionType > 1) {
        return ImportFileSelection;
    }
    
    int mismatchAdj = -1;
    int mailAdj = -1;
    int printAdj = -1;
    if (showMismatchSwitch) {
        mismatchAdj = 0;
    }
    if (self.includeEmailExport) {
        mailAdj = 0;
    }
    if (printSupported) {
        printAdj = 0;
    }
    if (indexPath.row == 1 + mismatchAdj) {
        return ExportFileSelection;
    }
    else if (indexPath.row == 2 + mismatchAdj && self.includeEmailExport) {
        return ExportEmailSelection;
    }
    else if (indexPath.row == 3 + mismatchAdj + mailAdj) {
        return ExportOpenInSelection;
    }
    else if (printSupported && indexPath.row == 4 + mismatchAdj + mailAdj) {
        return ExportPrintSelection;
    }
    else if (indexPath.row == 5 + mismatchAdj + mailAdj + printAdj) {
        if (self.includeImport) {
            return ImportFileSelection;
        }
        else if (self.locationName.length > 0) {
            return QRCodeSelection;
        }
    }
    
    return ExportLimitMismatchSwitch;
}

- (void)mismatchSwitchChanged:(UISwitch *)mismatchSwitch
{
    exportMismatchOnly = mismatchSwitch.on;
}

- (void)prepPrint
{
    if (self.pendingSaveToFileOps == nil) {
        self.pendingSaveToFileOps = [[DTCBGOperationsWorker alloc] init];
    }
    
    PreparePrintOutputOperation *ppoo = nil;

    if (self.categoryTitle.length > 0) {
        ppoo = [[PreparePrintOutputOperation alloc] initWithCategoryPrintLabel:self.categoryTitle
                                                                     withItems:self.itemsToExport
                                                                  withDelegate:self];
    }
    else {
        ppoo = [[PreparePrintOutputOperation alloc] initWithCompareLimit:exportMismatchOnly
                                                               withItems:self.itemsToExport
                                                        forLocationLabel:self.locationName
                                                            withDelegate:self];
    }
    
    NSString *key = @"printKey";
    ppoo.key = key;
    [self.pendingSaveToFileOps.bgOpInProgress setObject:ppoo forKey:key];
    [self.pendingSaveToFileOps.bgOpQueue addOperation:ppoo];
}

- (void)saveExportFile
{
    NSString *fileName = [NSString stringWithString:self.exportFileName];
    
    if (exportMismatchOnly) {
        fileName = [fileName stringByAppendingString:NSLocalizedString(@"limitedMisMatchFileName", @"limitedMisMatchFileName_lim")];
    }
    
    if (exportFileStyle == SaveOpDCZStyle) {
        if ([fileName hasSuffix:@".dcz"] == NO) {
            fileName = [fileName stringByAppendingString:@".dcz"];
        }
    }
    else {
        if ([fileName hasSuffix:@".csv"] == NO) {
           fileName = [fileName stringByAppendingString:@".csv"];
        }
    }
    if (![self.pendingSaveToFileOps.bgOpInProgress.allKeys containsObject:fileName]) {
        if (self.pendingSaveToFileOps == nil) {
            self.pendingSaveToFileOps = [[DTCBGOperationsWorker alloc] init];
        }
        SaveOutputFilesOperation *sofo = [[SaveOutputFilesOperation alloc] initWithCompareCountLimit:exportMismatchOnly
                                                                                            forItems:self.itemsToExport
                                                                                    forLocationLabel:self.locationName
                                                                                       withFileStyle:exportFileStyle
                                                                                        withFileName:fileName
                                                                                        withDelegate:self];
        [self.pendingSaveToFileOps.bgOpInProgress setObject:sofo forKey:self.exportFileName];
        [self.pendingSaveToFileOps.bgOpQueue addOperation:sofo];
    }
    else {
        NSLog(@"  ~ pending export file already in queue");
    }
}

- (void)exportQRCode
{
    UIImage *qrImage = [self createQRImageForString:self.locationName withColor:[AppController sharedAppController].barButtonColor forSize:CGSizeMake(172.0f, 172.0f) includeTextInImage:YES];
    

    // turn to JPEG data
    NSData *d = UIImageJPEGRepresentation(qrImage, 0.9);
    //NSData *d = UIImagePNGRepresentation(qrImage);
    
    NSString *title = self.locationName;
    if (title.length > 12) {
        title = [title substringToIndex:12];
    }
    title = [title stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    NSString *outPathName = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"QRCode_%@.jpg", title]];
    
    [d writeToFile:outPathName atomically:YES];
                             
    exportedFileUrl = [NSURL fileURLWithPath:outPathName];
                             
    [self.delegate dataDocShareQRCodeImage:qrImage atFileURL:exportedFileUrl];
}

- (void)importFile
{
    chosenSelection = ImportFileSelection;
    if (limitSelectionType == 3) {
        // guided step-by-step import directions
        
    }
    else {
        //NSArray *docTypes = @[(NSString *)kUTTypeRTF, (NSString *)kUTTypeText, (NSString *)kUTTypePlainText, (NSString *)kUTTypeUTF8TabSeparatedText, (NSString *)kUTTypeUTF8PlainText];
        NSArray *docTypes = @[(NSString *)kUTTypeUTF8TabSeparatedText, (NSString *)kUTTypePlainText];
        UIDocumentMenuViewController *importMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:docTypes
                                                                                                       inMode:UIDocumentPickerModeImport];
        importMenu.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:importMenu animated:YES completion:nil];
        });
        
    }
    
}

- (UIImage *)createQRImageForString:(NSString *)text withColor:(UIColor *)color forSize:(CGSize)size includeTextInImage:(BOOL)includeText
{
    if (text == nil || text.length == 0) {
        return nil;
    }
    
    // size it
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    CIImage *qrImage = [[AppController sharedAppController] createQRCodeCIImageForString:text];
    
    UIImage *qrCodeImage = [UIImage imageWithCIImage:qrImage];
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    [qrCodeImage drawInRect:rect];
    
    UIImage *resultQRImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // color it
    resultQRImage = [self imageWithGradient:resultQRImage withStartColor:color withEndColor:[UIColor blackColor] atAngle:0];
    
    if (includeText) {
        CGFloat textSize = 18.0f;
        if (text.length > 15) {
            textSize = 16.0f;
        }
        UIImage *borderImage = [UIImage imageNamed:@"qrborder.png"];
        
        // add border around code with enough space for default sizing in 4x6 print
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, size.width * 4.0f, 24.0f)];
        textLabel.text = text;
        textLabel.font = [UIFont systemFontOfSize:textSize];
        textLabel.textColor = [UIColor blackColor];
        textLabel.textAlignment = NSTextAlignmentCenter;
        //textLabel.backgroundColor = [UIColor greenColor];
        
        CGRect fullRect = CGRectMake(0.0f, 0.0f, size.width * 4.0f, size.height + 64.0f);
        
        UIGraphicsBeginImageContextWithOptions(fullRect.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        
        [borderImage drawInRect:fullRect];
    
        // center code image just below text
        rect = CGRectMake(size.width * 2.0f - 0.50f * size.width, 22.0f, size.width, size.height);
        
        [resultQRImage drawInRect:rect];
        
        [textLabel.layer renderInContext:context];
        
        resultQRImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    
    return resultQRImage;
}

/**
 * copied from DTCodeColors
 * angleStart: from top-left corner
 */
- (UIImage *)imageWithGradient:(UIImage *)image withStartColor:(UIColor *)colorStart withEndColor:(UIColor *)colorEnd atAngle:(int)angleStart
{
    CGSize imageSize = image.size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    // translate since CG and UIImage have different start positions
    CGContextTranslateCTM(context, 0, imageSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    //CGContextDrawImage(context, rect, image.CGImage);
    
    // make gradient
    NSArray *colors = [NSArray arrayWithObjects:(id)colorStart.CGColor, (id)colorEnd.CGColor, nil];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, NULL);
    
    // position start and end points based on balance and angle
    // default case 0
    CGPoint startPoint = CGPointMake(0.0f, image.size.height);
    CGPoint endPoint = CGPointMake(image.size.width, 0.0f);
    
    switch (angleStart) {
        case 1:
            startPoint = CGPointMake(0.0f, 0.0f);
            endPoint = CGPointMake(image.size.width, 0.0f);
            break;
        case 2:
            startPoint = CGPointMake(0.0f, 0.0f);
            endPoint = CGPointMake(image.size.width, image.size.height);
            break;
        case 3:
            startPoint = CGPointMake(0.0f, 0.0f);
            endPoint = CGPointMake(0.0f, image.size.height);
        default:
            break;
    }
    
    //NSLog(@"points: %fx%f, %fx%f", startPoint.x, startPoint.y, endPoint.x, endPoint.y);
    
    // create mask
    CGImageRef maskRef = CGImageMaskCreate(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage), CGImageGetBitsPerComponent(image.CGImage), CGImageGetBitsPerPixel(image.CGImage), CGImageGetBytesPerRow(image.CGImage), CGImageGetDataProvider(image.CGImage), NULL, YES);
    
    // apply gradient
    CGContextClipToMask(context, rect, maskRef);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGImageRelease(maskRef);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    
    return resultImage;
}



@end
