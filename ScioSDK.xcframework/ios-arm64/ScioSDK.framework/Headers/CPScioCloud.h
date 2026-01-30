//
//  CPScioCloud.h
//  ConsumerPhysics
//
//  Created by Roee Kremer on 6/15/15.
//  Copyright (c) 2015 ConsumerPhysics. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SCSampleRawData;

extern NSString *const CPScioCloudErrorDomain;

#pragma mark - CP Scio Login ViewController
/**
 `CPScioLoginViewController` is using to present a login UI for the user.
 
 You can 2 options to open the login view controller:
 1. create it programatically and present it using your current view controller.
 CPScioLoginViewController will preset login form with username and password fields, login and cancel button.
 it will dismiss itself upon completion of login action (succesful or failure) or pressing the cancel button
 
 2. Use the "showLoginWithCompletion" method. 
 In this case, it won't dismiss itself, and the caller can use the completion to dismiss the view controller.
 Params:
 completion- success is used for login success/failure. error contains the error in case of failure (reason is available in error userInfo).
 inNavigationController- show login screen in navigation controller. If "Yes", login view controller contains a "cancel" button.
 presentingViewController- current view controller to display the login view controller. 
*/

@interface CPScioLoginViewController : UIViewController

- (void)showLoginWithCompletion:(void (^)(BOOL success , NSError *error))completion inNavigationController:(BOOL)inNavigationController presentingViewController:(UIViewController *)presentingViewController;
+ (CPScioLoginViewController *)loginViewController;

@end


#pragma mark - CP Scio User

typedef NS_ENUM(NSInteger, CPUserStatus) {
    CPUserStatusActive,
    CPUserStatusInactive,
    CPUserStatusSignPending,
    CPUserStatusSuspended
};

/**
 `CPScioUser` is returned by [CPScioCloud getUserWithCompletion:] and holds some user details for a successful logined user.
*/
@interface CPScioUser : NSObject
@property (strong,nonatomic,readonly) NSString *first_name;
@property (strong,nonatomic,readonly) NSString *last_name;
@property (strong,nonatomic,readonly) NSString *username;
@property (assign,nonatomic,readonly) CPUserStatus userStatus;
@end

typedef NS_ENUM(NSUInteger, CPScioModelAttributeType) {
    CPScioModelAttributeTypeNumeric,
    CPScioModelAttributeTypeString,
    CPScioModelAttributeTypeDate
};

typedef NS_ENUM(NSUInteger, CPScioModelType) {
    CPScioModelTypeClassification,
    CPScioModelTypeEstimation
};

typedef NS_ENUM(NSUInteger, CPScioModelScanType) {
    CPScioModelSingleScan,
    CPScioModelMultipleScan
};

#pragma mark - CP Scio Model Info
@interface CPScioModelInfo : NSObject

@property (strong,nonatomic,readonly) NSString *name;
@property (strong,nonatomic,readonly) NSString *identifier;
@property (strong,nonatomic,readonly) NSString *collection_name;
@property (unsafe_unretained,nonatomic,readonly) int requiredScansCount;

@end

#pragma mark - CP Consumer Physics Model Info
@interface CPConsumerPhysicsModelInfo : CPScioModelInfo

@property (strong,nonatomic,readonly) NSArray <NSString *> *supportedSCiOVersions;

@end

#pragma mark - CP Scio Model
@interface CPScioModel : NSObject

@property (strong,nonatomic,readonly) NSString *name;
@property (strong,nonatomic,readonly) NSString *modelID;
@property (readonly) CPScioModelAttributeType attributeType;
@property (strong,nonatomic,readonly) NSString *attributeUnits;
@property (strong,nonatomic,readonly) id attributeValue;
@property (readonly) CPScioModelType modelType;
@property (assign, nonatomic, readonly) double confidence;
@property (readonly) BOOL lowConfidence;
@property (readonly) CPScioModelScanType modelScanType;
@property (unsafe_unretained, nonatomic, readonly) int requiredScansCount;
@property (unsafe_unretained, nonatomic, readonly) int currentScanCount;
@property (assign, nonatomic) id aggregatedValue;

@end

@class CPScioReading;
/**
 'CPScioCloud' is your connection to ConsumerPhysics cloud. it is a singleton so use [CPScioCloud sharedInstance] for each call.
 before using, you have to set your client_id and scope. 
 you can check if you are login using isLoggedIn, if not you can use CPLoginVewController to login. 
*/

#pragma mark - CP Scio Cloud
@interface CPScioCloud : NSObject<NSURLSessionDataDelegate>

@property (strong,nonatomic) NSString *cliend_id;
@property (strong,nonatomic) NSString *redirect_uri;
@property (assign, nonatomic) BOOL enableLogs;
/** 
 Initialize/Return a CPScioCloud singleton object.
 @return a CPScioCloud instance
*/
+ (id)sharedInstance;

/** 
 check if login.
 @return YES for a valid login.
 @warning a login may expire after a period of time.
*/
- (BOOL)isLoggedIn;

/**
 perform a logout. 
*/
- (void)logout;

//- (void)requestWhenInUseAuthorization;
/**
 ask for the current logged in user's details.
 @param completion Notify asynchronously the success of the operation, retrieve user's details or an error (if failed).
 @see CPScioUser
*/
- (void)getUserWithCompletion:(void(^)(BOOL success, CPScioUser *user, NSError *error))completion;

/**
 ask for the an app models.
 @param completion Notify asynchronously the success of the operation, retrieve an array of CPScioModelInfo or an error (if failed).
 @see CPScioModelInfo
*/
- (void)getModelsWithCompletion:(void(^)(BOOL success, NSArray <CPScioModelInfo *>*models, NSError *error))completion;

/**
 ask for the ConsumerPhysics models.
 @param completion Notify asynchronously the success of the operation, retrieve an array of CPScioModelInfo or an error (if failed).
 @see CPScioModelInfo
 */
- (void)getCPModelsWithCompletion:(void(^)(BOOL success, NSArray <CPConsumerPhysicsModelInfo *>*models, NSError *error))completion;

/**
 ask for an analysis of a scanned substance.
 @param reading The result of a scan
 @see [CPScioDevice scanWithCompletion:]
 @param modelIdentifier of requested model to analyze
 @param useScanLimit use scan limit
 @param completion Notify asynchronously the success of the operation, retrieve an analyzed model (CPScioModel) or an error (if failed).
*/
- (void)analyzeReading:(CPScioReading *)reading modelIdentifier:(NSString *)identifier useScanLimit:(BOOL)useScanLimit completion:(void (^)(BOOL success,CPScioModel *model, NSError *error))completion;
- (void)analyzeReading:(CPScioReading *)reading modelIdentifier:(NSString *)identifier completion:(void (^)(BOOL success,CPScioModel *model, NSError *error))completion;

/**
 validating the calibration of the data was taken from the device
*/
- (void)validateCalibrationData:(SCSampleRawData *)whiteRef completion:(void (^)(BOOL isValid, NSError *serverError))completion;

/**
 validating the self test of the data was taken from the device
*/
- (void)validateSelfTestData:(SCSampleRawData *)whiteRef completion:(void (^)(BOOL isValid, NSError *serverError))completion;

/**
 ask for an analysis of a scanned substance for multiple models
 @param reading The result of a scan
 @see [CPScioDevice scanWithCompletion:]
 @param modelIdentifiers of requested models list to analyze
 @param useScanLimit use scan limit
 @param completion Notify asynchronously the success of the operation, retrieve an analyzed model (CPScioModel) or an error (if failed).
 */
- (void)analyzeReading:(CPScioReading *)reading modelIdentifiers:(NSArray <NSString *>*)identifiersList useScanLimit:(BOOL)useScanLimit completion:(void (^)(BOOL success, NSArray <CPScioModel *>*models, NSError *error))completion;
- (void)analyzeReading:(CPScioReading *)reading modelIdentifiers:(NSArray <NSString *>*)identifiersList completion:(void (^)(BOOL success, NSArray <CPScioModel *>*models, NSError *error))completion;

/**
 get SCiO device version
 @param deviceID is the SCiO device ID
 @param completion Notify asynchronously the SCiO version or an error (if failed).
 */
- (void)getSCiOVersionByDeviceID:(NSString *)deviceID completion:(void(^)(NSString *SCiOVersion, NSError *error))completion;

/**
 clear current scan session by reseting the state_info parameter which we send to server
 */
- (void)clearScanSession;

#warning Code for set Environment - Only for Testing, for release hide this functions

- (void)selectEnvironmentViewController:(UIViewController *)vc completion:(void (^ __nullable)(void))completion;

- (NSString *_Nullable)getEnvironmentName;

@end
