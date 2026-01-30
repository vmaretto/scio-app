//
//  SARenameDeviceViewController.h
//  ConsumerPhysics
//
//  Created by Daniel David on 07/06/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SARenameDeviceViewControllerProtocol <NSObject>

@property(nonatomic, copy) void (^onFinishBlock)(NSString *newName, UIViewController *vc);

@end


@interface SARenameDeviceViewController : UIViewController<SARenameDeviceViewControllerProtocol>

@property (strong, nonatomic) NSString *currentName;

@end
