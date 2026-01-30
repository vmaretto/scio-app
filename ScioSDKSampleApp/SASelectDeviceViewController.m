//
//  SASelectDeviceViewController.m
//  ConsumerPhysics
//
//  Created by Roee Kremer on 6/23/15.
//  Copyright (c) 2015 ConsumerPhysics. All rights reserved.
//

#import "SASelectDeviceViewController.h"
#import <ScioSDK/ScioSDK.h>

@interface SASelectDeviceViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong,nonatomic) NSArray <CPScioDeviceInfo *>*devices;

@end

@implementation SASelectDeviceViewController

@synthesize onFinishBlock = _onFinishBlock;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[CPScioDevice sharedInstance] disconnentDevice];
    self.title = @"Select SCiO";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = nil;
    self.tableView.alwaysBounceVertical = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)cancelAction:(id)sender {
    if (self.onFinishBlock) {
        self.onFinishBlock(nil, self);
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    __weak typeof(&*self)weakSelf = self;
    [[CPScioDevice sharedInstance] discoverDevicesWithCompletion:^(NSArray *devices) {
        weakSelf.devices = devices;
        [weakSelf.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *name = ((CPScioDeviceInfo *)self.devices[indexPath.row]).name;
    cell.textLabel.text = name.length ? name : @"missing name";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.onFinishBlock) {
        self.onFinishBlock(self.devices[indexPath.row], self);
        return;
    }
}

@end
