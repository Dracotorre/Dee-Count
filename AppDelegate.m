//
//  AppDelegate.m
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 v1, AppController_iPad (parts of); now just an app delegate
//  - for ARC
//  - for new SplitViewController in iOS 8 and using storyboard
//  - launch decisions and StartupOperation moved to MasterView
//  - moved user defaults setting to proper place

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MasterViewController.h"
#import "AppController.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    
    splitViewController.delegate = self;
    
    // give controller a restoration ID
    //splitViewController.restorationIdentifier = NSStringFromClass([splitViewController class]);
    
    // set color for all button items
    if([UINavigationBar conformsToProtocol:@protocol(UIAppearanceContainer)]) {
        [UINavigationBar appearance].tintColor = [[AppController sharedAppController] barButtonColor];
    }
    
    
    [[AppController sharedAppController] cleanDocumentsDirectory];
    [[AppController sharedAppController] cleanTempDirectory];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    [defaults setValue:versionString forKey:@"version_preference"];
    
    if ([defaults objectForKey:@"show_negate_toggle_preference"]  == nil) {
        [defaults setBool:YES forKey:@"show_negate_toggle_preference"];
    }
    if ([defaults objectForKey:@"show_QR_searchButton_preference"] == nil) {
        [defaults setBool:NO forKey:@"show_QR_searchButton_preference"];
    }
    if ([defaults objectForKey:@"autoSetItemInput_preference"] == nil) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [defaults setBool:YES forKey:@"autoSetItemInput_preference"];
        }
        else [defaults setBool:NO forKey:@"autoSetItemInput_preference"];
    }
    
    [[AppController sharedAppController] updateDefaults:defaults];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(defaultsChanged:)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
    
    // updated from 2010 v1: moved launch decisions to MasterView, now just pass the incoming URL and let Master decide
    
    //DetailViewController *detailViewController = (DetailViewController *)[navigationController.viewControllers objectAtIndex:0];
    
    UINavigationController *rootNavController = [splitViewController.viewControllers firstObject];
    MasterViewController *masterView = (MasterViewController *)[rootNavController.viewControllers firstObject];
    
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
    
    [masterView setLaunchWithURL:url];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *rootNavController = [splitViewController.viewControllers firstObject];
    if ([[rootNavController.viewControllers firstObject] isKindOfClass:[MasterViewController class]]) {
        MasterViewController *masterView = (MasterViewController *)[rootNavController.viewControllers firstObject];
        [masterView saveStatus];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[AppController sharedAppController] saveContext];
    [[AppController sharedAppController] applicationEnteredBackground];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[AppController sharedAppController] applicationEnteredForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[AppController sharedAppController] saveContext];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url isFileURL]) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *rootNavController = [splitViewController.viewControllers firstObject];
        MasterViewController *masterView = (MasterViewController *)[rootNavController.viewControllers firstObject];
        
        [masterView setLaunchWithURL:url];
        
        return YES;
    }
    return NO;
}

- (void)defaultsChanged:(NSNotification *)notification
{
    NSUserDefaults *defaults = (NSUserDefaults *)[notification object];
    
    BOOL qrFinderOn = [AppController sharedAppController].showQRFinder;
    
    [[AppController sharedAppController] updateDefaults:defaults];
    
    if (qrFinderOn != [AppController sharedAppController].showQRFinder) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *rootNavController = [splitViewController.viewControllers firstObject];
        if ([[rootNavController.viewControllers firstObject] isKindOfClass:[MasterViewController class]]) {
            MasterViewController *masterView = (MasterViewController *)[rootNavController.viewControllers firstObject];
            
            [masterView scanQRDefaultPrefChanged:[AppController sharedAppController].showQRFinder];
        }
    }
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}


- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    
    if ([navigationController.topViewController isKindOfClass:[DetailViewController class]]) {
        DetailViewController *detailView = (DetailViewController *)navigationController.topViewController;
        [detailView splitViewModeChangedTo:displayMode];
    }
}



#pragma mark - state restoration
/*
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}
*/
@end
