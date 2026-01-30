//
//  SASelectModelViewController.m
//  ConsumerPhysics
//
//  Created by Daniel David on 07/06/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//

#import "SASelectModelViewController.h"
#import <ScioSDK/ScioSDK.h>

@interface SASelectModelViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SASelectModelViewController

@synthesize onFinishBlock = _onFinishBlock;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select Model";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView.rowHeight = 70;
    self.tableView.tableFooterView = nil;
    self.tableView.alwaysBounceVertical = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
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
    cell.textLabel.text = name.length ? name : @"missing name";
    if (modelInfo.collection_name)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"collection name:%@\nrequired scans:%d", modelInfo.collection_name, modelInfo.requiredScansCount];
    else
        cell.detailTextLabel.text = [NSString stringWithFormat:@"required scans:%d", modelInfo.requiredScansCount];
    
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
