//
//  SAHomeViewController.m
//  ConsumerPhysics
//
//  Created by Daniel David on 06/06/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//
//  Modified: Added MiniOrto integration
//

#import "SAHomeViewController.h"
#import <ScioSDK/ScioSDK.h>
#import "SASampleFileUtils.h"
#import "SASelectDeviceViewController.h"
#import "OLGhostAlertView.h"
#import "SASelectModelViewController.h"
#import "SARenameDeviceViewController.h"
#import "SADevicePowerSaverViewController.h"

typedef NS_ENUM(NSInteger, SACloudAPIOption) {
    SACloudAPIOptionLogin,
    SACloudAPIOptionLogout,
    SACloudAPIOptionModels,
    SACloudAPIOptionCPModels,
    SACloudAPIOptionAnalyze,
    SACloudAPIOptionUseScanLimit,
    SADeviceAPIOptionClearScans,
    SACloudAPIOptionSCiOVersion
};

#warning Code only for Testing, for release remove this
typedef NS_ENUM(NSInteger, SAAppOtherOption) {
    SAAppOtherOptionEnvironment
};

typedef NS_ENUM(NSInteger, SADeviceAPIOption) {
    SADeviceAPIOptionBrowse,
    SADeviceAPIOptionConnect,
    SADeviceAPIOptionDisconnect,
    SADeviceAPIOptionCalibrate,
    SADeviceAPIOptionCheckCalibration,
    SADeviceAPIOptionSelfTest,
    SADeviceAPIOptionScan,
    SADeviceAPIOptionRename,
    SADeviceAPIOptionPowerSaver,
    SADeviceAPIOptionBatteryStatus
};

NSString *const SACloudAPIString = @"Cloud API";
NSString *const SADeviceAPIString = @"Device API";
NSString *const SAAppOtherString = @"Other";

NSString *const SALastScanFileName = @"SALastScanFileName";
NSString *const SALastCalibrationFileName = @"SALastCalibrationFileName";

@interface SAHomeViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *sampleAppVersion;

@property (weak, nonatomic) IBOutlet UILabel *scioNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *calibrationStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *modelLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSDictionary *items;
@property (strong, nonatomic) NSArray *sectionsTitles;

@property (strong, nonatomic) CPScioReading *scanReading;
@property (strong, nonatomic) CPScioDeviceInfo *currentDevice;
@property (strong, nonatomic) CPScioModelInfo *currentModel;

@property (assign, nonatomic) CPScioDeviceState deviceState;

@property (strong, nonatomic) NSString *deviceName;

@property (assign, nonatomic) BOOL useScanLimit;

@end

@implementation SAHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *appLongVersion = [NSString stringWithFormat:@"%@.%@", [[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] copy], [[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleVersionKey] copy]];

    self.sampleAppVersion.text = appLongVersion;
    self.scioNameLabel.text = @"";
    self.statusLabel.text = @"Not Connected";
    self.calibrationStatusLabel.text = @"Not Calibrated";
    self.userNameLabel.text = @"Not Logged in";
    self.modelLabel.text = @"Not Selected";
    
    self.sdkVersionLabel.text = [NSString stringWithFormat:@"%.2f", ScioSDKVersionNumber];
    
    // Default value - Yes
    self.useScanLimit = YES;
    
    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = nil;
    self.tableView.alwaysBounceVertical = NO;
    
    self.items = @{
        SACloudAPIString : @[
            @(SACloudAPIOptionLogin),
            @(SACloudAPIOptionLogout),
            @(SACloudAPIOptionModels),
            @(SACloudAPIOptionCPModels),
            @(SACloudAPIOptionAnalyze),
            @(SACloudAPIOptionUseScanLimit),
            @(SADeviceAPIOptionClearScans),
            @(SACloudAPIOptionSCiOVersion)],
        SADeviceAPIString : @[
            @(SADeviceAPIOptionBrowse),
            @(SADeviceAPIOptionConnect),
            @(SADeviceAPIOptionDisconnect),
            @(SADeviceAPIOptionCalibrate),
            @(SADeviceAPIOptionCheckCalibration),
            @(SADeviceAPIOptionSelfTest),
            @(SADeviceAPIOptionScan),
            @(SADeviceAPIOptionRename),
            @(SADeviceAPIOptionPowerSaver),
            @(SADeviceAPIOptionBatteryStatus)],
#warning Code only for Testing, for release remove this
        SAAppOtherString: @[
            @(SAAppOtherOptionEnvironment)
        ],
    };

    // self.sectionsTitles = @[self.items allKeys];
    self.sectionsTitles = @[SADeviceAPIString, SACloudAPIString, SAAppOtherString];
    
    [CPScioDevice sharedInstance]; // just to power on BT
    
    self.deviceState = CPScioDeviceStateDisconnected;
    self.deviceName = [[CPScioDevice sharedInstance] deviceName];
    
    // Update device status
    [self updateDeviceStatus];
    
    __weak typeof(&*self)weakSelf = self;
    // This can be use start scanning (calibrateWithCompletion or scanWithCompletion)
    [[CPScioDevice sharedInstance] setDeviceButtonBlock:^{
        [weakSelf toastWithTitle:@"SCiO Device" message:@"Button clicked"];
    }];
    
    if ([[CPScioCloud sharedInstance] isLoggedIn]) {
        [self getUserInfo];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionsTitles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionsTitles[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionTitle = self.sectionsTitles[section];
    NSArray *sectionItems = self.items[sectionTitle];
    return sectionItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self getCellTextForIndexPath:indexPath];
    cell.accessoryType = [self getCellAccessoryCheckmark:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sectionTitle = self.sectionsTitles[indexPath.section];
    NSArray *sectionItems = self.items[sectionTitle];
    
    if ([sectionTitle isEqualToString:SACloudAPIString]) {
        SACloudAPIOption cloudApiOption = (SACloudAPIOption)[sectionItems[indexPath.row] intValue];
        
        switch (cloudApiOption) {
            case SACloudAPIOptionLogin:
                [self loginAPI];
                break;
            case SACloudAPIOptionLogout:
                [self logoutAPI];
                break;
            case SACloudAPIOptionModels:
                [self modelsAPI];
                break;
            case SACloudAPIOptionCPModels:
                [self cpModelsAPI];
                break;
            case SACloudAPIOptionAnalyze:
                [self AnalyzeAPI];
                break;
            case SACloudAPIOptionUseScanLimit:
                [self UseScanLimit];
                break;
            case SADeviceAPIOptionClearScans:
                [self clearScans];
                break;
            case SACloudAPIOptionSCiOVersion:
                [self scioVersionAPI];
                break;
        }
    }
#warning Code only for Testing, for release remove this
    else if ([sectionTitle isEqualToString:SAAppOtherString]) {
        SAAppOtherOption appOtherOption = (SAAppOtherOption)[sectionItems[indexPath.row] intValue];
        
        switch (appOtherOption) {
            case SAAppOtherOptionEnvironment:
                [[CPScioCloud sharedInstance] selectEnvironmentViewController:self completion:^{
                    [self clearScans];
                    [self logoutAPI];
                    [self.tableView reloadData];
                }];
                break;
        }
    }
    else
    {
        SADeviceAPIOption deviceApiOption = (SADeviceAPIOption)[sectionItems[indexPath.row]intValue];
        
        switch (deviceApiOption)
        {
            case SADeviceAPIOptionBrowse:
                [self openSelectDeviceScreen];
                break;
            case SADeviceAPIOptionConnect:
                [self connectAPI];
                break;
            case SADeviceAPIOptionDisconnect:
                [self disconnectAPI];
                break;
            case SADeviceAPIOptionCalibrate:
                [self calibrateAPI];
                break;
            case SADeviceAPIOptionCheckCalibration:
                [self checkCalibrationAPI];
                break;
            case SADeviceAPIOptionSelfTest:
                [self selfTestAPI];
                break;
            case SADeviceAPIOptionScan:
                [self scanAPI];
                break;
            case SADeviceAPIOptionRename:
                [self openRenameScreen];
                break;
            case SADeviceAPIOptionPowerSaver:
                [self openPowerSaverScreen];
                break;
            case SADeviceAPIOptionBatteryStatus:
                [self batteryStatusAPI];
                break;
        }
    }
}

#pragma mark - Cloud API

- (void)loginAPI {
    NSLog(@"loginAPI");
    CPScioLoginViewController *vc = [CPScioLoginViewController loginViewController];
    __weak typeof(&*vc)weakVC = vc;
    __weak typeof(&*self)weakSelf = self;
    
    [vc showLoginWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [weakSelf getUserInfo];
            [weakVC dismissViewControllerAnimated:YES completion:nil];
        } else {
            [weakVC dismissViewControllerAnimated:YES completion:nil];
            [weakSelf alertWithTitle:@"Failed to login" message:error.userInfo[@"Error"]];
        }
    } inNavigationController:YES presentingViewController:self];
}

- (void)logoutAPI {
    NSLog(@"logoutAPI");
    [self toastWithTitle:@"Logout" message:@""];
    [[CPScioCloud sharedInstance] logout];
    self.userNameLabel.text = @"Not Logged in";
    self.modelLabel.text = @"Not Connected";
}

- (void)modelsAPI {
    NSLog(@"modelsAPI");
    
    if (![[CPScioCloud sharedInstance] isLoggedIn]) {
        [self alertWithTitle:@"Login required" message:@"You must login in order to get the models list"];
        return;
    }
    
    [self toastWithTitle:@"Models" message:@"Getting models"];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioCloud sharedInstance] getModelsWithCompletion:^(BOOL success, NSArray *models, NSError *error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf modelsScreenWithModels:models];
            });
            return;
        }
        
        // Error
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
        });
    }];
}

- (void)cpModelsAPI {
    NSLog(@"cpModelsAPI");

    if (![[CPScioCloud sharedInstance] isLoggedIn])
    {
        [self alertWithTitle:@"Login required" message:@"You must login in order to get the models list"];
        return;
    }

    [self toastWithTitle:@"CP models" message:@"Getting CP models"];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioCloud sharedInstance] getCPModelsWithCompletion:^(BOOL success, NSArray *models, NSError *error) {
        
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf modelsScreenWithModels:models];
            });
            return;
        }
        
        // Error
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
        });
    }];
}

- (void)AnalyzeAPI {
    NSLog(@"AnalyzeAPI");
    
    if (!self.modelLabel.text.length)
    {
        [self alertWithTitle:@"Missing model" message:@"Select a model before analyzing a scan"];
        return;
    }
    
    if (![[CPScioCloud sharedInstance] isLoggedIn])
    {
        [self alertWithTitle:@"Login required" message:@"You must login in order to get analyze"];
        return;
    }
    
    CPScioReading *lastScan = [SASampleFileUtils readArchiveWithFileName:SALastScanFileName];
    
    if (!lastScan)
    {
        [self alertWithTitle:@"Missing Scan" message:@"Scan before analyzing"];
        return;
    }
    
    if (!self.currentModel)
    {
        [self alertWithTitle:@"A model isn't selected" message:@"Make sure you select a model"];
        return;
    }
    
    [self toastWithTitle:@"Analyzing" message:[NSString stringWithFormat:@"Analyzing last saved scan. Model: %@", self.modelLabel.text]];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioCloud sharedInstance] analyzeReading:lastScan
                                 modelIdentifier:self.currentModel.identifier
                                    useScanLimit:self.useScanLimit
                                      completion:^(BOOL success, CPScioModel *model, NSError *error) {
        NSLog(@"analyze succeded: %i", success);
        if (success)
        {
            NSString *message = nil;
            NSString *type = model.modelType == CPScioModelTypeClassification ? @"Classification" : @"Estimation";
            
            if (model.modelScanType == CPScioModelMultipleScan && model.currentScanCount < model.requiredScansCount)
            {
                // Still have to do more analyzes *value
                NSString *value = nil;
                if ([model.attributeValue isEqualToString:@"NA"])
                    value = [model.aggregatedValue isKindOfClass:[NSNull class]] ? @"N/A" : model.aggregatedValue;
                else
                    if (model.attributeValue == nil)
                    {
                        value = @"Unkown Material";
                    }
                    else
                    {
                        value = @"N/A";
                    }
                message = [NSString stringWithFormat:@"%@\nType: %@\nValue: %@\nScan %d more times", model.name,
                           type,
                           value,
                           model.requiredScansCount - model.currentScanCount];
            }
            else
            {
                BOOL shouldAddConfidenceString = model.modelType == CPScioModelTypeClassification && model.confidence > 0;
                NSString *confidenceString = shouldAddConfidenceString ? [NSString stringWithFormat:@"(%.2lf)", model.confidence] : @"";
                
                if (model.modelScanType == CPScioModelSingleScan)
                {
                    NSString *value = model.attributeValue;
                    if ([model.attributeValue isKindOfClass:[NSNull class]] || model.attributeValue == nil)
                    {
                        value = @"Unkown Material";
                    }
                    
                    if (model.attributeType == CPScioModelAttributeTypeNumeric)
                    {
                        value = [NSString stringWithFormat:@"%.2lf", [value doubleValue]];
                    }
                    message = [NSString stringWithFormat:@"Type: %@\nValue: %@ %@", type, value, confidenceString];
                }
                else
                {
                    // We have finished the multiple scan session
                    message = [NSString stringWithFormat:@"%@\nType: %@\nValue: %@ %@\nScan session complete", model.name, type, model.aggregatedValue, confidenceString];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alertWithTitle:@"Results" message:message];
                // Send to MiniOrto
                [weakSelf sendToMiniOrto:model];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alertWithTitle:[error.userInfo objectForKey:NSLocalizedDescriptionKey] message:[error.userInfo objectForKey:NSLocalizedFailureReasonErrorKey]];
            });
        }
    }];
}

#pragma mark - MiniOrto Integration

- (void)sendToMiniOrto:(CPScioModel *)model {
    NSLog(@"Sending to MiniOrto: %@", model.name);
    
    // Build payload
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"modelName"] = model.name ?: @"Unknown";
    payload[@"modelType"] = model.modelType == CPScioModelTypeClassification ? @"classification" : @"estimation";
    payload[@"source"] = @"scio-ios-app";
    payload[@"timestamp"] = @([[NSDate date] timeIntervalSince1970] * 1000);
    
    if (model.attributeValue && ![model.attributeValue isKindOfClass:[NSNull class]]) {
        if (model.attributeType == CPScioModelAttributeTypeNumeric) {
            payload[@"value"] = @([model.attributeValue doubleValue]);
        } else {
            payload[@"value"] = model.attributeValue;
        }
    }
    
    if (model.aggregatedValue && ![model.aggregatedValue isKindOfClass:[NSNull class]]) {
        payload[@"aggregatedValue"] = model.aggregatedValue;
    }
    
    if (model.confidence > 0) {
        payload[@"confidence"] = @(model.confidence);
    }
    
    payload[@"lowConfidence"] = @(model.lowConfidence);
    
    // Send to MiniOrto
    NSURL *url = [NSURL URLWithString:@"https://mini-orto.vercel.app/api/receive-scio"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];
    
    if (jsonError) {
        NSLog(@"MiniOrto JSON error: %@", jsonError);
        return;
    }
    
    request.HTTPBody = jsonData;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"MiniOrto send error: %@", error);
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"MiniOrto response: %ld", (long)httpResponse.statusCode);
                if (data) {
                    NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"MiniOrto data: %@", responseStr);
                }
            }
        }];
    [task resume];
}

- (void)UseScanLimit {
    self.useScanLimit = !self.useScanLimit;
    [self.tableView reloadData];
}

- (void)scioVersionAPI {
    NSLog(@"scioVersionAPI");
    
    if (!self.scioNameLabel.text.length) {
        [self alertWithTitle:@"No Device" message:@"Please connect a device"];
        return;
    }
    
    if (![[CPScioCloud sharedInstance] isLoggedIn]) {
        [self alertWithTitle:@"Login required" message:@"You must login in order to get the SCiO Device Version"];
        return;
    }
    
    NSString *deviceID = [[CPScioDevice sharedInstance] getDeviceID];
    if (!deviceID) {
        NSLog(@"Missing SCiO device ID");
        [self alertWithTitle:@"Device ID is missing" message:@"Please connect a SCiO device and try again"];
        return;
    }
        
    NSLog(@"SCiO device ID:%@", deviceID);
    NSString *deviceName = [[CPScioDevice sharedInstance] deviceName];
    NSLog(@"SCiO device name:%@", deviceName);
    
    [self toastWithTitle:@"Get SCiO Version" message:[NSString stringWithFormat:@"Device Name: %@\nDevice ID: %@", deviceName, deviceID]];

    __weak typeof(&*self)weakSelf = self;
    [[CPScioCloud sharedInstance] getSCiOVersionByDeviceID:[[CPScioDevice sharedInstance] getDeviceID] completion:^(NSString *SCiOVersion, NSError *error) {
        NSLog(@"SCiO version:%@", SCiOVersion);
        [weakSelf alertWithTitle:@"SCiO Version" message:SCiOVersion];
    }];
}

- (void)getUserInfo {
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioCloud sharedInstance] getUserWithCompletion:^(BOOL success, CPScioUser *user, NSError *error) {
        if (!success) {
            [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.userNameLabel.text = user.username;
        });
    }];
}

#pragma mark - Device API

- (void)openSelectDeviceScreen {
    NSLog(@"openSelectDeviceScreen");

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    UINavigationController *nvc = [storyboard instantiateViewControllerWithIdentifier:@"select-device-navigation-controller"];
    SASelectDeviceViewController *vc = ((SASelectDeviceViewController *)nvc.topViewController);
    
    self.deviceState = CPScioDeviceStateDisconnected;
    
    __weak typeof(&*self)weakSelf = self;
    vc.onFinishBlock = ^(CPScioDeviceInfo *selected, UIViewController *presenting) {
        weakSelf.currentDevice = selected;
        weakSelf.deviceName = selected.name;
        if (selected) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.scioNameLabel.text = selected.name;
                weakSelf.statusLabel.text = @"Not connected";
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.scioNameLabel.text = @"";
            });
        }
        
        [presenting dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void)connectAPI {
    NSLog(@"connectAPI");
    
    if (!self.currentDevice) {
        [self alertWithTitle:@"No Device" message:@"Select device before connecting"];
        return;
    }
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] connectDevice:self.currentDevice completion:^(NSError *error) {
        if (!error)
        {
            [weakSelf toastWithTitle:@"SCiO is connected" message:@"SCiO device connected successfully"];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
            });
        }
    }];
}

- (void)disconnectAPI {
    NSLog(@"disconnectAPI");
    self.statusLabel.text = @"Not connected";
    self.calibrationStatusLabel.text = @"Not Calibrated";
    self.scioNameLabel.text = @"";
    self.deviceState = CPScioDeviceStateDisconnected;
    
    [[CPScioDevice sharedInstance] disconnentDevice];
}

- (void)calibrateAPI {
    NSLog(@"calibrateAPI");

    if (![[CPScioDevice sharedInstance] isReady]) {
        [self alertWithTitle:@"No Device" message:@"Please connect a device"];

        return;
    }
    
    if (self.deviceState != CPScioDeviceStateConnected) {
        [self alertWithTitle:@"Device isn't connected" message:@"Make sure your device is on"];
        return;
    }
    
    [self toastWithTitle:@"CalibrateAPI" message:@"Calibrating"];
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] calibrateWithCompletion:^(BOOL success, CPScioCalibrationReading *calibrationReading, NSError *error) {
        NSLog(@"calibration: %i", success);
        
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.calibrationStatusLabel.text = @"Not calibrated";
                [weakSelf alertWithTitle:@"Calibration Failed" message:@"Please try again."];

            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.calibrationStatusLabel.text = @"Calibrated";
            [weakSelf toastWithTitle:@"Calibration Completed" message:@"You can scan now"];
        });
        
    }];
}

- (void)checkCalibrationAPI {
    
    __weak typeof(&*self)weakSelf = self;
    if (![[CPScioDevice sharedInstance] isSCiOCalibrationOptional]) {
        [self toastWithTitle:@"Check Calibration" message:@"Checking calibration"];
        [[CPScioDevice sharedInstance] isCalibrationValid:^(BOOL isValid, NSError *error) {
            NSLog(@"calibration is valid: %i", isValid);
            
            if (!isValid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.calibrationStatusLabel.text = @"Not Calibrated";
                    [weakSelf alertWithTitle:@"Calibration is invalid" message:@"Calibrate before scan"];
                });
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.calibrationStatusLabel.text = @"Calibrated";
                [weakSelf toastWithTitle:@"Check Calibration" message:@"Calibration Valid"];
            });
        }];
    } else {
        [self toastWithTitle:@"Check Calibration" message:@"Calibration is optioanl"];
    }
}

- (void)selfTestAPI {
    NSLog(@"selfTestAPI");
    
    if (![[CPScioDevice sharedInstance] isReady]) {
        [self alertWithTitle:@"No Device" message:@"Please connect a device"];
        return;
    }
    
    if (self.deviceState != CPScioDeviceStateConnected) {
        [self alertWithTitle:@"Device isn't connected" message:@"Make sure your device is on"];
        return;
    }
    
    [self toastWithTitle:@"Self Test" message:@"Self testing"];
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] selfTestWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"self test: %i", success);
        
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf toastWithTitle:@"Self Test Completed" message:@"Self Test Success"];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alertWithTitle:@"Self Test Failed" message:@"Please try again."];
            });
        }
    }];
}

- (void)scanAPI {
    NSLog(@"scanAPI");

    if (![[CPScioDevice sharedInstance] isReady]) {
        [self alertWithTitle:@"No Device" message:@"Please connect a device"];
        return;
    }
    
    if (self.deviceState != CPScioDeviceStateConnected) {
        [self alertWithTitle:@"Device isn't connected" message:@"Make sure your device is on"];
        return;
    }
    
    __weak typeof(&*self)weakSelf = self;

    [self toastWithTitle:@"scanAPI" message:@"Scanning"];
    [[CPScioDevice sharedInstance] scanWithCompletion:^(BOOL success, CPScioReading *reading, NSError *error) {
        NSLog(@"Scan: %i",success);
        if (!success)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey] message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
            });
            return;
        }
        
        weakSelf.scanReading = reading;
        if (![SASampleFileUtils storeToDisk:reading fileName:SALastScanFileName])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf alertWithTitle:@"Failure" message:@"Failed to save last scan"];
            });
        }
        [weakSelf toastWithTitle:@"Scan Completed" message:@"You can analyze a model now."];
    }];
}

- (void)openRenameScreen {
    NSLog(@"openRenameScreen");
    
    if (![self checkDeviceStatus]) {
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UINavigationController *nvc = [storyboard instantiateViewControllerWithIdentifier:@"rename-device-navigation-controller"];
    SARenameDeviceViewController *vc = ((SARenameDeviceViewController *)nvc.topViewController);
    
    vc.currentName = [[CPScioDevice sharedInstance] deviceName];
    __weak typeof(&*self)weakSelf = self;
    vc.onFinishBlock = ^(NSString *newName, UIViewController *presenting) {
        if (newName.length) {
            [weakSelf renameDeviceWithName:newName];
        }
        
        [presenting dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self presentViewController:nvc animated:YES completion:nil];

}

- (void)renameDeviceWithName:(NSString *)name {
    NSLog(@"renameDeviceWithName:%@", name);
    
    if (![self checkDeviceStatus]) {
        return;
    }
    
    [self toastWithTitle:@"Renaming SCiO" message:[NSString stringWithFormat:@"New name: %@", name]];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] renameDeviceWithName:name completion:^(BOOL success, NSError *error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.scioNameLabel.text = name;
                weakSelf.deviceName = name;
            });
            return;
        }
        
        [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];

    }];
}


- (void)openPowerSaverScreen {
    NSLog(@"openPowerSaverScreen");
    
    if (![self checkDeviceStatus]) {
        return;
    }
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] getDevicePowerOffTimeoutWithCompletion:^(NSUInteger minutesVal) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController *nvc = [storyboard instantiateViewControllerWithIdentifier:@"device-power-saver-navigation-controller"];
        SADevicePowerSaverViewController *vc = ((SADevicePowerSaverViewController *)nvc.topViewController);

        vc.valueInMinutes = minutesVal;
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        vc.onFinishBlock = ^(NSNumber *newMinutes, UIViewController *presenting) {
            if (newMinutes) {
                NSUInteger minutes = [newMinutes unsignedLongValue];
                if (minutes >= SCMinTimeoutMinutesValue && minutes <= SCMaxTimeoutMinutesValue) {
                    [strongSelf setPowerOffTimeoutWithTime:minutes];
                }
            }
            [presenting dismissViewControllerAnimated:YES completion:nil];
        };

        [weakSelf presentViewController:nvc animated:YES completion:nil];
        
    }];
}

- (void)setPowerOffTimeoutWithTime:(NSUInteger)minutes {
    NSLog(@"setPowerOffTimeoutWithTime: %lu", minutes);
    
    if (![self checkDeviceStatus]) {
        return;
    }
    
    [self toastWithTitle:@"Set Power off timeout SCiO" message:[NSString stringWithFormat:@"New power off timeout: %lu minutes", minutes]];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] setPowerOffTimeoutWithMinutes:minutes completion:^(BOOL success, NSError *error) {
        if (!success) {
            if (error) {
                [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey] message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
            } else {
                [weakSelf alertWithTitle:@"Error" message:@"Failed to set timeout"];
            }
        }
    }];
}

- (BOOL)checkDeviceStatus {
    BOOL result = YES;
    
    if (result && ![[CPScioDevice sharedInstance] isReady]) {
        [self alertWithTitle:@"No Device" message:@"Please connect a device"];
        result = NO;
    }
    
    if (result && self.deviceState != CPScioDeviceStateConnected) {
        [self alertWithTitle:@"Device isn't connected" message:@"Make sure your device is on"];
        result = NO;
    }
    
    return result;
}

- (void)batteryStatusAPI {
    NSLog(@"batteryStatusAPI");

    if (![[CPScioDevice sharedInstance] isReady]) {
        [self alertWithTitle:@"No Device" message:@"Please connect a device"];

        return;
    }

    if (self.deviceState != CPScioDeviceStateConnected) {
        [self alertWithTitle:@"Device isn't connected" message:@"Make sure your device is on"];

        return;
    }
    
    [self toastWithTitle:@"Battery Status" message:@"Read battery status"];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] getBatteryStatusWithCompletion:^(double percentage, BOOL isCharging, NSError *error) {
        if (error) {
            [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
            return;
        }
        
        [weakSelf alertWithTitle:@"Battery status" message:[NSString stringWithFormat:@"Status: %@\nPercentage: %.0f", isCharging ? @"Charging" : @"Not charging", percentage]];
    }];
}

- (void)clearScans {
    self.scanReading = nil;
    [[CPScioCloud sharedInstance] clearScanSession];
    
    [self alertWithTitle:@"Done!" message:@"Scans were cleared.."];
}

#pragma mark - Helpers

- (void)updateDeviceStatus {
    __weak typeof(&*self)weakSelf = self;

    [[CPScioDevice sharedInstance] setStateChangedBlock:^(CPScioDeviceState state) {
        NSString *status = @"";
        NSString *calibration = @"";
        weakSelf.deviceState = state;
        
        switch (state) {
            case CPScioDeviceStateDisconnected:
                status = @"Disconnected";
                calibration = @"Not Calibrated";
                break;
            case CPScioDeviceStateConnected:
                status = @"Connected";
                weakSelf.scioNameLabel.text = weakSelf.deviceName ?: [[CPScioDevice sharedInstance] deviceName];
                [weakSelf updateCalibrationStatus];
                break;
            case CPScioDeviceStateConnecting:
                status = @"Connecting...";
                calibration = @"Not Calibrated";
                break;
            default:
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.statusLabel.text = status;
            if (calibration.length > 0) {
                weakSelf.calibrationStatusLabel.text = calibration;
            }
        });
        NSLog(@"Device state: %zd",state);
    }];
}

- (void)updateCalibrationStatus {
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] isCalibrationValid:^(BOOL isValid, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.calibrationStatusLabel.text = isValid ? @"Calibrated" : @"Not Calibrated";
        });
    }];
}

- (NSString *)getCellTextForIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionTitle = self.sectionsTitles[indexPath.section];
    NSArray *sectionItems = self.items[sectionTitle];
    
    NSString *cellText = @"";
    if ([sectionTitle isEqualToString:SACloudAPIString])
    {
        SACloudAPIOption cloudApiOption = (SACloudAPIOption)[sectionItems[indexPath.row] intValue];
        
        switch (cloudApiOption)
        {
            case SACloudAPIOptionLogin:
                cellText = @"Login";
                break;
            case SACloudAPIOptionLogout:
                cellText = @"Logout";
                break;
            case SACloudAPIOptionModels:
                cellText = @"Models";
                break;
            case SACloudAPIOptionCPModels:
                cellText = @"ConsumerPhysics Models";
                break;
            case SACloudAPIOptionAnalyze:
                cellText = @"Analyze";
                break;
            case SACloudAPIOptionUseScanLimit:
                cellText = @"Use Scan Limit";
                break;
            case SADeviceAPIOptionClearScans:
                cellText = @"Clear Scans";
                break;
            case SACloudAPIOptionSCiOVersion:
                cellText = @"SCiO Version";
                break;
        }
    }
#warning Code only for Testing, for release remove this
    else if ([sectionTitle isEqualToString:SAAppOtherString])
    {
        SAAppOtherOption appOtherOption = (SAAppOtherOption)[sectionItems[indexPath.row] intValue];
        
        switch (appOtherOption)
        {
            case SAAppOtherOptionEnvironment:
                cellText = [NSString stringWithFormat:@"Environment - %@", [[CPScioCloud sharedInstance] getEnvironmentName]];
                break;
        }
    }
    else
    {
        SADeviceAPIOption deviceApiOption = (SADeviceAPIOption)[sectionItems[indexPath.row]intValue];
        
        switch (deviceApiOption)
        {
            case SADeviceAPIOptionBrowse:
                cellText = @"Browse";
                break;
            case SADeviceAPIOptionConnect:
                cellText = @"Connect";
                break;
            case SADeviceAPIOptionDisconnect:
                cellText = @"Disconnect";
                break;
            case SADeviceAPIOptionCalibrate:
                cellText = @"Calibrate";
                break;
            case SADeviceAPIOptionCheckCalibration:
                cellText = @"Check Calibration";
                break;
            case SADeviceAPIOptionSelfTest:
                cellText = @"Self Test";
                break;
            case SADeviceAPIOptionScan:
                cellText = @"Scan";
                break;
            case SADeviceAPIOptionRename:
                cellText = @"Rename";
                break;
            case SADeviceAPIOptionPowerSaver:
                cellText = @"Power Saver";
                break;
            case SADeviceAPIOptionBatteryStatus:
                cellText = @"Battery Status";
                break;
        }
    }
    
    return cellText;
}

- (UITableViewCellAccessoryType)getCellAccessoryCheckmark:(NSIndexPath *)indexPath {
    NSString *sectionTitle = self.sectionsTitles[indexPath.section];
    NSArray *sectionItems = self.items[sectionTitle];
    
    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    if ([sectionTitle isEqualToString:SACloudAPIString])
    {
        SACloudAPIOption cloudApiOption = (SACloudAPIOption)[sectionItems[indexPath.row] intValue];
        
        if (cloudApiOption == SACloudAPIOptionUseScanLimit)
        {
            accessoryType = self.useScanLimit ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
    }
    
    return accessoryType;
}

- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    NSLog(@"Alert. Title: %@. Message:%@", title, message);
    
    UIAlertController *alert =[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *OKButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:OKButton];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)toastWithTitle:(NSString *)title message:(NSString *)message {

    __weak typeof(&*self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        OLGhostAlertView *toast = [[OLGhostAlertView alloc] initWithTitle:title message:message timeout:3.0 dismissible:YES];
        toast.position = OLGhostAlertViewPositionBottom;
        toast.style = OLGhostAlertViewStyleDark;
        toast.bottomContentMargin = 44.0f;
        toast.completionBlock = ^(void) { };
    
        [toast showInView:weakSelf.view];
    });
}

- (void)modelsScreenWithModels:(NSArray <CPConsumerPhysicsModelInfo *>*)models {
    NSLog(@"openSelectDeviceScreen");
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UINavigationController *nvc = [storyboard instantiateViewControllerWithIdentifier:@"select-model-navigation-controller"];
    SASelectModelViewController *vc = ((SASelectModelViewController *)nvc.topViewController);
    vc.models = models;
    
    __weak typeof(&*self)weakSelf = self;
    vc.onFinishBlock = ^(CPScioModelInfo *selected, UIViewController *presenting, NSError *error) {
        
        weakSelf.currentModel = selected;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.modelLabel.text = selected ? selected.name : @"Not Selected";
        });
        
        [presenting dismissViewControllerAnimated:YES completion:nil];
        if (error)
        {
            [weakSelf alertWithTitle:error.userInfo[NSLocalizedDescriptionKey]  message:error.userInfo[NSLocalizedFailureReasonErrorKey]];
        }
        
    };
    
    [weakSelf presentViewController:nvc animated:YES completion:nil];
}

@end
