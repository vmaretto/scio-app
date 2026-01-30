//
//  SASelectDeviceViewController.h
//  ConsumerPhysics
//
//  Created by Roee Kremer on 6/23/15.
//  Copyright (c) 2015 ConsumerPhysics. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CPScioDeviceInfo;

@protocol SASelectDeviceViewControllerProtocol <NSObject>

@property(nonatomic, copy) void (^onFinishBlock)(CPScioDeviceInfo *selected, UIViewController *vc);

@end

@interface SASelectDeviceViewController : UIViewController<SASelectDeviceViewControllerProtocol>

@end
