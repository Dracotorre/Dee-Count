//
//  DataDocViewController.h
//  Dee Count
//
//  Created by David G Shrock on 8/26/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SaveOutputFilesOperation.h"
#import "PreparePrintOutputOperation.h"
#import "DocFormatPickViewController.h"

@protocol DataDocDelegate;

@interface DataDocViewController : UITableViewController <UIDocumentMenuDelegate, SaveOutputFilesOperationDelegate, PreparePrintOutputDelegate, DocFormatPickerDelegate>


@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, weak) id<DataDocDelegate>delegate;


@property (nonatomic, strong) NSArray *itemsToExport;
/**
 * without file extension
 */
@property (nonatomic, strong) NSString *exportFileName;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSString *categoryTitle;
@property (nonatomic, strong) NSString *headerText;
@property (nonatomic) BOOL includeImport;
@property (nonatomic) BOOL showMismatchSwitch;
@property (nonatomic) BOOL includeEmailExport;
@property (nonatomic) BOOL needsDoneButton;

- (instancetype)initForImportOnlyWithGuided:(BOOL)isGuided;
- (instancetype)initForExportOnly;


@end


@protocol DataDocDelegate <NSObject>

- (void)dataDocSendMailWithFileURL:(NSURL *)exportedFileUrl forFileName:(NSString *)fileName;
- (void)dataDocumentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker forImport:(BOOL)isImport;
- (void)dataDocOpenInWithURL:(NSURL *)exportedFileUrl;
- (void)printRequestForOutputText:(NSString *)text;
- (void)dataDocShareQRCodeImage:(UIImage *)qrImage atFileURL:(NSURL *)exportedFileUrl;

@end