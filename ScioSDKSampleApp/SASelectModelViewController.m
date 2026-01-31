//
//  SASelectModelViewController.m
//  ConsumerPhysics
//
//  Created by Daniel David on 07/06/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//
//  Modified by Clawdbot - Added version compatibility display
//

#import "SASelectModelViewController.h"
#import <ScioSDK/ScioSDK.h>

@interface SASelectModelViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *currentScioVersion;

@end

@implementation SASelectModelViewController

@synthesize onFinishBlock = _onFinishBlock;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select Model";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView.rowHeight = 85;  // Increased for more info
    self.tableView.tableFooterView = nil;
    self.tableView.alwaysBounceVertical = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    // Get current SCiO version from device
    self.currentScioVersion = @"scio_1_2"; // Default, will be updated
    [[CPScioCloud sharedInstance] getSCiOVersionByDeviceID:[[CPScioDevice sharedInstance] getDeviceID] completion:^(NSString *SCiOVersion, NSError *error) {
        if (SCiOVersion) {
            self.currentScioVersion = SCiOVersion;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
}

- (void)cancelAction:(id)sender {
    if (self.onFinishBlock) {
        self.onFinishBlock(nil, self, nil);
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    CPConsumerPhysicsModelInfo *modelInfo = (CPConsumerPhysicsModelInfo *)self.models[indexPath.row];
    NSString *name = modelInfo.name;
    
    // Check compatibility
    BOOL isCompatible = NO;
    NSString *versionsStr = @"universal";
    
    if (modelInfo.supportedSCiOVersions.count > 0) {
        versionsStr = [modelInfo.supportedSCiOVersions componentsJoinedByString:@", "];
        for (NSString *version in modelInfo.supportedSCiOVersions) {
            if ([version isEqualToString:self.currentScioVersion]) {
                isCompatible = YES;
                break;
            }
        }
    } else {
        // No version restriction = universal
        isCompatible = YES;
    }
    
    // Set title with compatibility indicator
    NSString *compatEmoji = isCompatible ? @"✅" : @"⚠️";
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", compatEmoji, name.length ? name : @"missing name"];
    
    // Build detail text with versions info
    NSMutableString *detailText = [NSMutableString string];
    if (modelInfo.collection_name) {
        [detailText appendFormat:@"Collection: %@\n", modelInfo.collection_name];
    }
    [detailText appendFormat:@"Scans: %d | Versions: %@", modelInfo.requiredScansCount, versionsStr];
    if (!isCompatible) {
        [detailText appendFormat:@"\n⚠️ Your device: %@", self.currentScioVersion];
    }
    cell.detailTextLabel.text = detailText;
    cell.detailTextLabel.numberOfLines = 3;
    
    // Color based on compatibility
    if (isCompatible) {
        cell.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0]; // Light green
    } else {
        cell.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.9 alpha:1.0]; // Light orange
    }
    
    if (modelInfo.supportedSCiOVersions.count)
    {
        cell.imageView.image = [UIImage imageNamed:@"icon-info"];
        cell.imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellInfoDidTap:)];
        cell.imageView.tag = indexPath.row;
        [cell.imageView addGestureRecognizer:tap];
    }
    else
    {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CPConsumerPhysicsModelInfo *modelInfo = (CPConsumerPhysicsModelInfo *)self.models[indexPath.row];
    
    // Check compatibility
    BOOL isCompatible = NO;
    if (modelInfo.supportedSCiOVersions.count > 0) {
        for (NSString *version in modelInfo.supportedSCiOVersions) {
            if ([version isEqualToString:self.currentScioVersion]) {
                isCompatible = YES;
                break;
            }
        }
    } else {
        isCompatible = YES;
    }
    
    if (!isCompatible) {
        // Show warning but allow selection
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚠️ Version Mismatch"
            message:[NSString stringWithFormat:@"This model may not be compatible with your device (%@).\n\nSupported versions: %@\n\nAnalysis might fail or give degraded results. Try anyway?", 
                self.currentScioVersion,
                [modelInfo.supportedSCiOVersions componentsJoinedByString:@", "]]
            preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        __weak typeof(self) weakSelf = self;
        UIAlertAction *tryAction = [UIAlertAction actionWithTitle:@"Try Anyway" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (weakSelf.onFinishBlock) {
                weakSelf.onFinishBlock(modelInfo, weakSelf, nil);
            }
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:tryAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (self.onFinishBlock) {
        self.onFinishBlock(self.models[indexPath.row], self, nil);
        return;
    }
}

#pragma mark - Helpers 

- (void)cellInfoDidTap:(UITapGestureRecognizer *)recognizer {
    NSInteger row = recognizer.view.tag;

    CPConsumerPhysicsModelInfo *modelInfo = (CPConsumerPhysicsModelInfo *)self.models[row];
    NSString *suppertedSCiOversions = [modelInfo.supportedSCiOVersions.description substringWithRange:NSMakeRange(1, modelInfo.supportedSCiOVersions.description.length - 2)];
    NSString *message = [@"Suported SCiO versions:\n" stringByAppendingString:suppertedSCiOversions];
    
    [self alertWithTitle:modelInfo.name message:message];
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

@end
