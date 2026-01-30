//
//  SADevicePowerSaverViewController.h
//  ScioESDKSampleApp
//
//  Created by Opiata Roman on 29.07.2020.
//  Copyright © 2020 ConsumerPhysics. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SADevicePowerSaverViewControllerProtocol <NSObject>

@property(nonatomic, copy) void (^onFinishBlock)(NSNumber *newMinutes, UIViewController *vc);

@end

@interface SADevicePowerSaverViewController : UIViewController<SADevicePowerSaverViewControllerProtocol>

@property (assign, nonatomic) NSUInteger valueInMinutes;

@end
