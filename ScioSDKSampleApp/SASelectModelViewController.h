//
//  SASelectModelViewController.h
//  ConsumerPhysics
//
//  Created by Daniel David on 07/06/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CPConsumerPhysicsModelInfo;

@protocol SASelectModelViewControllerProtocol <NSObject>

@property(nonatomic, copy) void (^onFinishBlock)(CPConsumerPhysicsModelInfo *selected, UIViewController *vc, NSError *error);

@end


@interface SASelectModelViewController : UIViewController<SASelectModelViewControllerProtocol>

@property (strong,nonatomic) NSArray <CPConsumerPhysicsModelInfo *>*models;

@end
