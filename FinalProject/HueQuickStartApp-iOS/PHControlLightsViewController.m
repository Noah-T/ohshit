/*******************************************************************************
 Copyright (c) 2013 Koninklijke Philips N.V.
 All Rights Reserved.
 ********************************************************************************/

#import "PHControlLightsViewController.h"
#import "PHAppDelegate.h"
#import <MyoKit/MyoKit.h>
#import <HueSDK_iOS/HueSDK.h>
#import "PHLoadingViewController.h"
#define MAX_HUE 65535

@interface PHControlLightsViewController()

@property (nonatomic,weak) IBOutlet UILabel *bridgeMacLabel;
@property (nonatomic,weak) IBOutlet UILabel *bridgeIpLabel;
@property (nonatomic,weak) IBOutlet UILabel *bridgeLastHeartbeatLabel;
@property (nonatomic,weak) IBOutlet UIButton *randomLightsButton;

//Myo
@property (strong, nonatomic) TLMPose *currentPose;



@property (nonatomic) int gryoDataCounter;
@property (nonatomic) int lastPose;
@property (nonatomic,strong) NSString *poseLast;
@property (nonatomic) int accelDataCounter;


@property (nonatomic) float xMin;
@property (nonatomic) float xMax;
@property (nonatomic) float yMin;
@property (nonatomic) float yMax;
@property (nonatomic) float zMin;
@property (nonatomic) float zMax;
@property (nonatomic) float lengthMin;
@property (nonatomic) float lengthMax;

@property (nonatomic) BOOL restActive;
@property (nonatomic) BOOL fistActive;
@property (nonatomic) BOOL dblTap;
@property (nonatomic) BOOL waveIn;
@property (nonatomic) BOOL waveOut;
@property (nonatomic) BOOL fingersSpreadActive;
@property (nonatomic) BOOL verticalActive;
@property (nonatomic) BOOL hammerInProgress;

@property (nonatomic) BOOL grpOn;
@property (nonatomic) float xRotation;
@property (nonatomic) int grpHue;
@property (nonatomic) int grpBrt;
@property (nonatomic) int grpSat;


@property (nonatomic) int currentLightIndex;
@property (nonatomic) int currentHue;
@property (nonatomic) int currentSaturation;
@property (nonatomic) int currentBrightness;

- (IBAction)pairMyo:(id)sender;
//Philips
@property (strong, nonatomic) PHHueSDK *PHHueSDK;

@end


@implementation PHControlLightsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.xMin = 0.0;
    self.xMax = 0.0;
    self.yMin = 0.0;
    self.yMax = 0.0;
    self.zMin = 0.0;
    self.zMax = 0.0;
    self.xRotation = 0.0;
    self.grpOn = YES;
    self.grpHue = 3000;
    self.grpBrt = 20;
    self.grpSat = 20;
    
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    PHLightState *lightState = [[PHLightState alloc] init];
    
    [lightState setHue:[NSNumber numberWithInt:self.grpHue]];
    [lightState setOnBool:self.grpOn];
    [lightState setTransitionTime:[NSNumber numberWithInt:@0]];
    [lightState setBrightness:[NSNumber numberWithInt:self.grpBrt]];
    [lightState setSaturation:[NSNumber numberWithInt:self.grpSat]];
    
    [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:lightState completionHandler:^(NSArray *errors){
        if (errors != nil) {
            NSLog(@"Lights initialized");
        } else {
            for (NSError *error in errors) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }
    }];
    
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    // Register for the local heartbeat notifications
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:@"Find bridge" style:UIBarButtonItemStylePlain target:self action:@selector(findNewBridgeButtonAction)];
    [bbi setTitleTextAttributes:@{
                                  NSFontAttributeName : [UIFont fontWithName:@"Avenir" size:18.0],
                                  NSForegroundColorAttributeName : [UIColor blackColor]
                                  }forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = bbi;
    
    UIColor *orange = [UIColor colorWithRed:255/255.0
                                      green:129.0/255.0
                                       blue:100.0/255
                                      alpha:1.0];
    
    
    self.navigationItem.title = @"OhShit";
    self.navigationController.navigationBar.barTintColor = orange;
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName : [UIColor blackColor],
                                                                    NSFontAttributeName : [UIFont fontWithName:@"Avenir" size:24.0]
                                                                    };
    
    self.navigationItem.title = @"QuickStart";
    
    [self noLocalConnection];
    
    //Myo Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(didReceiveOrientationEvent:)
//                                                 name:TLMMyoDidReceiveOrientationEventNotification
//                                               object:nil];
    
    // Posted when a new pose is available from a TLMMyo.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveGyroscopeEvent:)
                                                 name:TLMMyoDidReceiveGyroscopeEventNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAccelerometerEvent:)
                                                 name:TLMMyoDidReceiveAccelerometerEventNotification
                                               object:nil];
    
    self.PHHueSDK = [[PHHueSDK alloc] init];
    [self.PHHueSDK startUpSDK];
    [self.PHHueSDK enableLogging:NO];
    
    
    
    /***************************************************
     The SDK will send the following notifications in response to events:
     
     - LOCAL_CONNECTION_NOTIFICATION
     This notification will notify that the bridge heartbeat occurred and the bridge resources cache data has been updated
     
     - NO_LOCAL_CONNECTION_NOTIFICATION
     This notification will notify that there is no connection with the bridge
     
     - NO_LOCAL_AUTHENTICATION_NOTIFICATION
     This notification will notify that there is no authentication against the bridge
     *****************************************************/
    
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(notAuthenticated) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
    
    /***************************************************
     The local heartbeat is a regular timer event in the SDK. Once enabled the SDK regular collects the current state of resources managed
     by the bridge into the Bridge Resources Cache
     *****************************************************/
    [self.PHHueSDK enableLocalConnection];
    [self.PHHueSDK setLocalHeartbeatInterval:0.5f forResourceType: RESOURCES_LIGHTS];
    
    
}

- (UIRectEdge)edgesForExtendedLayout {
    return UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)localConnection{
    
    [self loadConnectedBridgeValues];
    
}

- (void)noLocalConnection{
    self.bridgeLastHeartbeatLabel.text = @"Not connected";
    [self.bridgeLastHeartbeatLabel setEnabled:NO];
    self.bridgeIpLabel.text = @"Not connected";
    [self.bridgeIpLabel setEnabled:NO];
    self.bridgeMacLabel.text = @"Not connected";
    [self.bridgeMacLabel setEnabled:NO];
    
    [self.randomLightsButton setEnabled:NO];
}

- (void)loadConnectedBridgeValues{
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    
    // Check if we have connected to a bridge before
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil){
        
        // Set the ip address of the bridge
        self.bridgeIpLabel.text = cache.bridgeConfiguration.ipaddress;
        
        // Set the mac adress of the bridge
        self.bridgeMacLabel.text = cache.bridgeConfiguration.mac;
        
        // Check if we are connected to the bridge right now
        if (UIAppDelegate.phHueSDK.localConnected) {
            
            // Show current time as last successful heartbeat time when we are connected to a bridge
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            
            self.bridgeLastHeartbeatLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
            
            [self.randomLightsButton setEnabled:YES];
        } else {
            self.bridgeLastHeartbeatLabel.text = @"Waiting...";
            [self.randomLightsButton setEnabled:NO];
        }
    }
}

- (IBAction)selectOtherBridge:(id)sender{
    [UIAppDelegate searchForBridgeLocal];
}

- (IBAction)randomizeColoursOfConnectLights:(id)sender{
    [self.randomLightsButton setEnabled:NO];
    
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    for (PHLight *light in cache.lights.allValues) {
        
        PHLightState *lightState = [[PHLightState alloc] init];
        
        [lightState setHue:[NSNumber numberWithInt:arc4random() % MAX_HUE]];
        [lightState setBrightness:[NSNumber numberWithInt:254]];
        [lightState setSaturation:[NSNumber numberWithInt:254]];
        
        // Send lightstate to light
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                
                NSLog(@"Response: %@",message);
            }
            
            [self.randomLightsButton setEnabled:YES];
        }];
    }
}

- (void)findNewBridgeButtonAction{
    [UIAppDelegate searchForBridgeLocal];
}

- (IBAction)pairMyo:(id)sender {
    TLMSettingsViewController *settings = [[TLMSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settings animated:YES];
}

- (void)didReceivePoseChange:(NSNotification *)notification {
    NSDate *myDate = [[NSDate alloc] init];
    // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    self.currentPose = pose;
    // Handle the cases of the TLMPoseType enumeration, and change the color of helloLabel based on the pose we receive.
    NSInteger tstamp = [myDate timeIntervalSince1970];
    if(self.lastPose - tstamp <= -1){
        self.lastPose = (int)tstamp;
        [self clearStates];
        self.restActive = NO;
        switch (pose.type) {
            case TLMPoseTypeUnknown:
                NSLog(@"unknown pose");
                self.poseLast = @"unknown";
                break;
            case TLMPoseTypeRest:
                NSLog(@"Resting");
                self.poseLast = @"rest";
                self.restActive = YES;
                break;
            case TLMPoseTypeDoubleTap:
                NSLog(@"tappity tap tap tap!");
                self.poseLast = @"tap";
                [self toggleLights];
                self.dblTap = YES;
                break;
            case TLMPoseTypeFist:
                NSLog(@"fist!");
                self.poseLast = @"fist";
                self.fistActive = YES;
                break;
            case TLMPoseTypeWaveIn:             // Changes helloLabel's font to Courier New when the user is in a wave in pose.
                NSLog(@"wave in pose");
                self.poseLast = @"waveIn";
                self.waveIn = YES;
                break;
            case TLMPoseTypeWaveOut:
                NSLog(@"wave out");
                self.poseLast = @"waveOut";
                self.waveOut = YES;
                break;
            case TLMPoseTypeFingersSpread:
                NSLog(@"fingers spread");
                self.poseLast = @"spread";
                self.fingersSpreadActive = YES;
                break;
        }
        // Unlock the Myo whenever we receive a pose
        if (pose.type == TLMPoseTypeUnknown || pose.type == TLMPoseTypeRest) {
            // Causes the Myo to lock after a short period.
            [pose.myo unlockWithType:TLMUnlockTypeTimed];
        } else {
            // Keeps the Myo unlocked until specified.
            // This is required to keep Myo unlocked while holding a pose, but if a pose is not being held, use
            // TLMUnlockTypeTimed to restart the timer.
            [pose.myo unlockWithType:TLMUnlockTypeHold];
            // Indicates that a user action has been performed.
            [pose.myo indicateUserAction];
        }
    }
}

- (void)didReceiveGyroscopeEvent:(NSNotification *)notification {
    
    NSDate *myDate = [[NSDate alloc] init];
    NSInteger tstamp = [myDate timeIntervalSince1970];
    //Get the Gyro notification
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    NSArray *myLights = [cache.lights allValues];
    TLMGyroscopeEvent *gyro = notification.userInfo[@"kTLMKeyGyroscopeEvent"];
    
    //Increment counter
    if (self.gryoDataCounter - tstamp <= -1) {
        NSLog(@"Timestamp since LastGyro: %d",(int)(self.gryoDataCounter-tstamp));
        NSLog(@"Last Pose: %@", self.poseLast);
        self.gryoDataCounter = (int)tstamp;
        if (self.fistActive) {
            NSLog(@"Change the hue!");
            self.grpHue = (self.xRotation + 60) * 10 + self.grpHue;
            // Send lightstate to light
            if (self.grpHue < 0) {
                self.grpHue = 0;
            } else {
                if (self.grpHue > MAX_HUE) {
                    self.grpHue = MAX_HUE;
                }
            }
        } else if (self.fingersSpreadActive){
            self.grpBrt = self.xRotation + self.grpBrt;
            // Send lightstate to light
            if (self.grpBrt < 0) {
                self.grpBrt = 0;
            } else {
                if (self.grpBrt > 254) {
                    self.grpBrt = 254;
                }
            }
        } else if (self.waveIn){
            self.grpSat = self.xRotation + self.grpSat;
            // Send lightstate to light
            if (self.grpSat < 0) {
                self.grpSat = 0;
            } else {
                if (self.grpSat > 254) {
                    self.grpSat = 254;
                }
            }
        }
        
        
        if (!self.restActive){
            TLMGyroscopeEvent *gyro = notification.userInfo[@"kTLMKeyGyroscopeEvent"];
            self.xRotation += gyro.vector.x;
            NSLog(@"self.xRotation: %f", self.xRotation);
            
            PHLightState *lightState = [[PHLightState alloc] init];
            
            NSLog(@"H:%d, B:%d, S:%d",self.grpHue,self.grpBrt,self.grpSat);
            [lightState setHue:[NSNumber numberWithInt:self.grpHue]];
            [lightState setTransitionTime:[NSNumber numberWithInt:0]];
            [lightState setBrightness:[NSNumber numberWithInt:self.grpBrt]];
            [lightState setSaturation:[NSNumber numberWithInt:self.grpSat]];
            
            [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:lightState completionHandler:^(NSArray *errors){
                NSLog(@"State updated");
                if (errors == nil) {
                    NSLog(@"lightState.hue: %@", lightState.hue);
                    NSLog(@"lightState.brt: %@", lightState.brightness);
                    NSLog(@"lightState.sat: %@", lightState.saturation);
                } else {
                    for (NSError *error in errors) {
                        NSLog(@"Error: %@", [error localizedDescription]);
                    }
                }
            }];
        }
    }
    /*
     if (gyro.vector.x > self.xMax) {
     self.xMax = gyro.vector.x;
     }else if (gyro.vector.x < self.xMin) {
     self.xMin = gyro.vector.x;
     }
     
     if (gyro.vector.y > self.yMax) {
     self.yMax = gyro.vector.y;
     }else if (gyro.vector.y < self.yMin) {
     self.yMin = gyro.vector.y;
     }
     
     if (gyro.vector.z > self.zMax) {
     self.zMax = gyro.vector.z;
     }else if (gyro.vector.z < self.zMin) {
     self.zMin = gyro.vector.z;
     }
     
     if (GLKVector3Length(gyro.vector) > self.lengthMax){
     self.lengthMax = GLKVector3Length(gyro.vector);
     }else if (GLKVector3Length(gyro.vector) < self.lengthMin){
     self.lengthMin = GLKVector3Length(gyro.vector);
     }
     
     NSLog(@"\nxMin: %f\nxMax: %f\nyMin: %f\nyMax: %f\nzMin: %f\nzMax: %f\n", self.xMin, self.xMax, self.yMin, self.yMax, self.zMin, self.zMax);
     NSLog(@"\nlengthMin: %f\nlengthMax: %f\n", self.lengthMin, self.lengthMax);
     */
    
    
}

- (void)didReceiveAccelerometerEvent:(NSNotification *)notification {
    
    TLMAccelerometerEvent *accel = notification.userInfo[@"kTLMKeyAccelerometerEvent"];
    //    NSLog
    (@"\nx: %f\ny: %f\n z:%f",accel.vector.x, accel.vector.y, accel.vector.z);
    if (self.waveOut) {
        //Check for vertical position
        
        //Get vector
        //        if (accel.vector.x < 1.2 && accel.vector.x > 0.8 && accel.vector.y < 0.2 && accel.vector.y > -0.2 && accel.vector.z < 0.2 && accel.vector.z > -0.2) {
        //            self.verticalActive = YES;
        //            self.hammerInProgress = YES;
        //        }
        if(accel.vector.x > 0.2){
            self.verticalActive = YES;
            self.hammerInProgress = YES;
        }
        
        if (self.hammerInProgress) {
            if (accel.vector.x < 0.1){
//                [self toggleLights];
                self.hammerInProgress = NO;
            }
        }
    }
    
}


- (void)toggleLights
{
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    PHLightState *lightState = [[PHLightState alloc] init];
    self.grpOn = !self.grpOn;
    
    [lightState setOnBool:self.grpOn];
    [lightState setTransitionTime:[NSNumber numberWithInt:@0]];
    
    // Send lightstate to light
    [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:lightState completionHandler:^(NSArray *errors){
        if (errors != nil) {
            NSLog(@"Lights OUT!");
        } else {
            for (NSError *error in errors) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }
    }];
}
- (void)clearStates
{
    self.xRotation = 0.0;
    self.restActive = NO;
    self.fistActive = NO;
    self.waveIn = NO;
    self.dblTap = NO;
    self.fingersSpreadActive = NO;
}
@end

