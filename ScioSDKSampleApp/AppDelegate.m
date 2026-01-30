//
//  AppDelegate.m
//  ScioSDKSampleApp
//
//  Created by Roee Kremer on 6/23/15.
//  Copyright (c) 2015 ConsumerPhysics. All rights reserved.
//

#import "AppDelegate.h"
#import <ScioSDK/ScioSDK.h>
#import "LogglyLogger.h"
#import "LogglyFormatter.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSLog(@"ScioSDKVersionNumber: %.2f", ScioSDKVersionNumber);
    // Override point for customization after application launch.
    [[CPScioCloud sharedInstance] setCliend_id:@"4b5ac28b-28f9-4695-b784-b7665dfe3763"];
    [[CPScioCloud sharedInstance] setRedirect_uri:@"https://www.consumerphysics.com"];
    [[CPScioCloud sharedInstance] setEnableLogs:YES];
    [[CPScioDevice sharedInstance] setEnableLogs:YES];
    
    LogglyLogger *logglyLogger = [[LogglyLogger alloc] init];
    [logglyLogger setLogFormatter:[[LogglyFormatter alloc] init]];
    logglyLogger.logglyKey = @"af81540a-b3cd-40f5-8a7e-14b0eaf6ef39";

    // Set posting interval every 15 seconds, just for testing this out, but the default value of 600 seconds is better in apps
    // that normally don't access the network very often. When the user suspends the app, the logs will always be posted.
    logglyLogger.saveInterval = 15;
    
    [DDLog addLogger:logglyLogger];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
