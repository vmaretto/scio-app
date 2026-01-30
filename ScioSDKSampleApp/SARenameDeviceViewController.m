//
//  SARenameDeviceViewController.m
//  ConsumerPhysics
//
//  Created by Daniel David on 07/06/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//

#import "SARenameDeviceViewController.h"

@interface SARenameDeviceViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *currentNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@end

@implementation SARenameDeviceViewController

@synthesize onFinishBlock = _onFinishBlock;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Rename device";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    self.currentNameLabel.text = [NSString stringWithFormat:@"Current Name: %@", self.currentName ?: @"No name"];
    self.instructionsLabel.numberOfLines = 0;
    self.instructionsLabel.text = @"SCiO Device name cannot be longer than 16 chars";
    
    self.errorLabel.text = @"";
    
    self.nameTextField.delegate = self;
    self.nameTextField.returnKeyType = UIReturnKeySend;
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

- (IBAction)sendButtonAction:(id)sender {
    [self.nameTextField resignFirstResponder];
    if ([self validateDeviceNameLength]) {
        if (self.onFinishBlock) {
            self.onFinishBlock(self.nameTextField.text, self);
            return;
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)validateDeviceNameLength {
    if (!self.nameTextField.text.length) {
        self.errorLabel.text = @"Insert a new name";
        return NO;
    }
    
    if (self.nameTextField.text.length > 16) {
        self.errorLabel.text = @"Name must be up to 16 chars";
        return NO;
    }
    
    return  YES;;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.errorLabel.text = @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
