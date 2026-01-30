//
//  SADevicePowerSaverViewController.m
//  ScioESDKSampleApp
//
//  Created by Opiata Roman on 29.07.2020.
//  Copyright © 2020 ConsumerPhysics. All rights reserved.
//

#import "SADevicePowerSaverViewController.h"
#import <ScioSDK/CPScioDevice.h>

@interface SADevicePowerSaverViewController ()

@property (weak, nonatomic) IBOutlet UILabel *setTimeoutLabel;
@property (weak, nonatomic) IBOutlet UILabel *sliderValue;
@property (weak, nonatomic) IBOutlet UILabel *minutesLabel;

@property (weak, nonatomic) IBOutlet UISlider *minutesSlider;

@property (weak, nonatomic) IBOutlet UILabel *minValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *middleValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxValueLabel;

@property (weak, nonatomic) IBOutlet UIButton *setButton;

@end

@implementation SADevicePowerSaverViewController

@synthesize onFinishBlock = _onFinishBlock;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Device Power Saver";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.setTimeoutLabel.adjustsFontSizeToFitWidth = YES;
    self.setTimeoutLabel.minimumScaleFactor = 0.6;
    self.setTimeoutLabel.text = @"SCiO will turn off after:";
    
    UIColor *greenTextColor = [UIColor colorWithRed:92.0/255.0 green:175.0/255.0 blue:112.0/255.0 alpha:1];
    self.sliderValue.text = @"";
    self.sliderValue.textColor = greenTextColor;
    
    self.minutesLabel.text = @"minutes";
    self.minutesLabel.textColor = greenTextColor;
    self.minutesLabel.adjustsFontSizeToFitWidth = YES;
    self.minutesLabel.minimumScaleFactor = 0.7;
 
    self.minValueLabel.text = [NSString stringWithFormat:@"%luM", SCMinTimeoutMinutesValue];
    self.maxValueLabel.text = [NSString stringWithFormat:@"%luM", SCMaxTimeoutMinutesValue];
    self.middleValueLabel.text = [NSString stringWithFormat:@"%luM", (long)( ceil((SCMaxTimeoutMinutesValue - SCMinTimeoutMinutesValue) / 2.0) )];
    
    self.minutesSlider.minimumValue = SCMinTimeoutMinutesValue;
    self.minutesSlider.maximumValue = SCMaxTimeoutMinutesValue;
    
    self.sliderValue.text = [NSString stringWithFormat:@"%lu", (long)self.valueInMinutes];
    self.minutesSlider.value = self.valueInMinutes;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)cancelAction:(id)sender {
    if (self.onFinishBlock) {
        self.onFinishBlock(nil, self);
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)setButtonAction:(id)sender {
    self.valueInMinutes = [self.sliderValue.text intValue];
    
    if (self.onFinishBlock) {
        self.onFinishBlock([NSNumber numberWithUnsignedInteger:self.valueInMinutes], self);
        return;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sliderValueChanged:(id)sender {
    NSInteger sliderValue = lround(self.minutesSlider.value);
    [self.minutesSlider setValue:sliderValue animated:YES];
    self.sliderValue.text = [NSString stringWithFormat:@"%@", @(sliderValue)];
}

@end

