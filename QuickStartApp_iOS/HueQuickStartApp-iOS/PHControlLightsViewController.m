/*******************************************************************************
 Copyright (c) 2013 Koninklijke Philips N.V.
 All Rights Reserved.
 ********************************************************************************/

#import "PHControlLightsViewController.h"
#import "PHAppDelegate.h"
#import <MyoKit/MyoKit.h>
#import <HueSDK_iOS/HueSDK.h>
#define MAX_HUE 65535

@interface PHControlLightsViewController()

@property (nonatomic) int gryoDataCounter;
@property (nonatomic) int accelDataCounter;

@property (nonatomic,weak) IBOutlet UILabel *bridgeMacLabel;
@property (nonatomic,weak) IBOutlet UILabel *bridgeIpLabel;
@property (nonatomic,weak) IBOutlet UILabel *bridgeLastHeartbeatLabel;
@property (nonatomic,weak) IBOutlet UIButton *randomLightsButton;

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
@property (nonatomic) BOOL fingersSpreadActive;
@property (nonatomic) float xRotation;
@property (nonatomic) int grpHue;
@property (nonatomic) int grpBrt;
@property (nonatomic) int grpSat;

//Myo
@property (strong, nonatomic) TLMPose *currentPose;
@property (weak, nonatomic) IBOutlet UIButton *connectMyoButton;

@property (nonatomic) int currentLightIndex;
@property (nonatomic) int currentHue;
@property (nonatomic) int currentSaturation;
@property (nonatomic) int currentBrightness;

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
    self.grpHue = 0;
    self.grpBrt = 255;
    self.grpSat = 255;
    
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    PHLightState *lightState = [[PHLightState alloc] init];
    
    [lightState setHue:[NSNumber numberWithInt:self.grpHue]];
    [lightState setTransitionTime:[NSNumber numberWithInt:@0]];
    [lightState setBrightness:[NSNumber numberWithInt:self.grpBrt]];
    [lightState setSaturation:[NSNumber numberWithInt:self.grpSat]];
    
    [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:lightState completionHandler:^(NSArray *errors){
        if (errors != nil) {
            NSLog(@"lightState.hue: %@", lightState.hue);
            NSLog(@"lightState.brt: %@", lightState.brightness);
            NSLog(@"lightState.sat: %@", lightState.saturation);
            NSLog(@"State updated");
            
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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Find bridge" style:UIBarButtonItemStylePlain target:self action:@selector(findNewBridgeButtonAction)];
    
    self.navigationItem.title = @"QuickStart";
    
    [self noLocalConnection];
    
    //Myo Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationEvent:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    
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
    //Myo
    [self.connectMyoButton setEnabled:NO];
    
    self.currentLightIndex = 1;
    self.currentHue = 3000;
    self.currentSaturation = 20;
    self.currentBrightness = 20;
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
            
            //Connect and Configure Myo
            [self.connectMyoButton setEnabled:YES];
            
            
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
//                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
//                
//                NSLog(@"Response: %@",message);
            }
            
            [self.randomLightsButton setEnabled:YES];
        }];
    }
}

- (void)findNewBridgeButtonAction{
    [UIAppDelegate searchForBridgeLocal];
}

#pragma mark - Myo
- (IBAction)connectMyo:(id)sender
{
    TLMSettingsViewController *settings = [[TLMSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settings animated:YES];
}


- (void)didReceiveOrientationEvent:(NSNotification*)notification {
    TLMOrientationEvent *orientation = notification.userInfo[kTLMKeyOrientationEvent];
    
    //TODO: do something with the orientation object.
    
}
- (void)didReceivePoseChange:(NSNotification *)notification {
    // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    self.currentPose = pose;
    // Handle the cases of the TLMPoseType enumeration, and change the color of helloLabel based on the pose we receive.
    [self clearStates];
    switch (pose.type) {
        case TLMPoseTypeUnknown:
            NSLog(@"unknown pose");
        case TLMPoseTypeRest:
            NSLog(@"Resting");
            self.restActive = YES;
        case TLMPoseTypeDoubleTap:
            // Changes helloLabel's font to Helvetica Neue when the user is in a rest or unknown pose.
            //NSLog(@"Unknown, rest, double tap");
            break;
        case TLMPoseTypeFist:
            // Changes helloLabel's font to Noteworthy when the user is in a fist pose.
            [self clearStates];
            self.fistActive = YES;
            NSLog(@"fist!");
            [self changeLight1];
            break;
        case TLMPoseTypeWaveIn:             // Changes helloLabel's font to Courier New when the user is in a wave in pose.
            NSLog(@"wave in pose");
            //[self descreaseLightIndex];
            [self decreaseHue];
            break;
        case TLMPoseTypeWaveOut:
            // Changes helloLabel's font to Snell Roundhand when the user is in a wave out pose.
            NSLog(@"wave out");
            
            //[self increaseLightIndex];
            [self increaseHue];
            break;
        case TLMPoseTypeFingersSpread:
            [self clearStates];
            self.fingersSpreadActive = YES;
            NSLog(@"fingers spread");
            [self randomizeColorsForMyo];
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

- (void)didReceiveGyroscopeEvent:(NSNotification *)notification {
    
    //Get the Gyro notification
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    NSArray *myLights = [cache.lights allValues];
    TLMGyroscopeEvent *gyro = notification.userInfo[@"kTLMKeyGyroscopeEvent"];

    //Increment counter
    self.gryoDataCounter ++;
    if (self.gryoDataCounter == 20) {
        if (self.fistActive) {
            self.grpHue = self.xRotation + self.grpHue;
            // Send lightstate to light
            if (self.grpHue < 0) {
                self.grpHue = 0;
            } else {
                if (self.grpHue > MAX_HUE) {
                    self.grpHue = MAX_HUE;
                }
            }
        } else if (self.fingersSpreadActive){
            self.grpBrt = self.xRotation/2 + self.grpBrt;
            self.grpSat = self.xRotation/2 + self.grpSat;
            // Send lightstate to light
            if (self.grpBrt < 0) {
                self.grpBrt = 0;
            } else {
                if (self.grpBrt > 255) {
                    self.grpBrt = 255;
                }
            }
            
        }
        if (!self.restActive){
            TLMGyroscopeEvent *gyro = notification.userInfo[@"kTLMKeyGyroscopeEvent"];
            self.xRotation += gyro.vector.x;
            NSLog(@"self.xRotation: %f", self.xRotation);
            
            PHLightState *lightState = [[PHLightState alloc] init];
            
            [lightState setHue:[NSNumber numberWithInt:self.grpHue]];
            [lightState setTransitionTime:[NSNumber numberWithInt:@0]];
            [lightState setBrightness:[NSNumber numberWithInt:self.grpBrt]];
            [lightState setSaturation:[NSNumber numberWithInt:self.grpSat]];
            
            [bridgeSendAPI setLightStateForGroupWithId:@"0" lightState:lightState completionHandler:^(NSArray *errors){
                if (errors != nil) {
                    NSLog(@"lightState.hue: %@", lightState.hue);
                    NSLog(@"lightState.brt: %@", lightState.brightness);
                    NSLog(@"lightState.sat: %@", lightState.saturation);
                    NSLog(@"State updated");
                    
                } else {
                    for (NSError *error in errors) {
                        NSLog(@"Error: %@", [error localizedDescription]);
                    }
                }
            }];
        }
        
        self.gryoDataCounter = 0;
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
    /*
    self.accelDataCounter ++;
    if (self.accelDataCounter == 15) {
        
        TLMAccelerometerEvent *accel = notification.userInfo[@"kTLMKeyAccelerometerEvent"];
        //nslog(@"distance: \nx:%.2f\ny:%.2f\nz:%.2f\n",accel.vector.x, accel.vector.y, accel.vector.z);
        self.accelDataCounter = 0;
    }
    
    
    //ACCELEROMETER
    TLMAccelerometerEvent *gyro = notification.userInfo[@"kTLMKeyAccelerometerEvent"];

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
    }else if (GLKVector3Length(gyro.v
     ector) < self.lengthMin){
        self.lengthMin = GLKVector3Length(gyro.vector);
    }
    
    //NSLog(@"\nxMin: %f\nxMax: %f\nyMin: %f\nyMax: %f\nzMin: %f\nzMax: %f\n", self.xMin, self.xMax, self.yMin, self.yMax, self.zMin, self.zMax);
    //NSLog(@"\nlengthMin: %f\nlengthMax: %f\n", self.lengthMin, self.lengthMax);
    self.accelDataCounter ++;
    if (self.accelDataCounter == 10) {
        NSLog(@"\nx: %f\ny: %f\nz: %f", gyro.vector.x, gyro.vector.y, gyro.vector.z);
        self.accelDataCounter = 0;
    }
     
     */
}
- (void)randomizeColorsForMyo
{
    [self.randomLightsButton setEnabled:NO];
    
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    for (PHLight *light in cache.lights.allValues) {
        
        PHLightState *lightState = [[PHLightState alloc] init];
        
        [lightState setHue:[NSNumber numberWithInt:arc4random() % MAX_HUE]];
        [lightState setBrightness:[NSNumber numberWithInt:arc4random() % 254]];
        [lightState setSaturation:[NSNumber numberWithInt:arc4random() % 254]];
        
        
        
        // Send lightstate to light
        NSLog(@"setting the hue to: %@", lightState.hue);
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
//                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
//                
//                NSLog(@"Response: %@",message);
            }
            
            [self.randomLightsButton setEnabled:YES];
        }];
    }
}

- (void)changeLight1
{
    
    int lightSwitch;
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    //NSString *lightIndexString = [NSString stringWithFormat:@"%d", self.currentLightIndex];
    PHLight *firstLight = [cache.lights objectForKey:@"1"];
    PHLightState *firstLightState = firstLight.lightState;
    
    [firstLightState setHue:[NSNumber numberWithInt:self.currentHue]];
    [firstLightState setBrightness:[NSNumber numberWithInt: 254]];
    [firstLightState setSaturation:[NSNumber numberWithInt:self.currentSaturation]];
        lightSwitch = 1;
        //NSLog(@"light switch value is: %d", lightSwitch);
    
    
    
    [bridgeSendAPI updateLightStateForId:firstLight.identifier withLightState:firstLightState completionHandler:^(NSArray *errors) {
        if (errors != nil) {
            NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
           
          NSLog(@"Response: %@",message);
        }
    }];
}

- (void)increaseLightIndex
{
    if (self.currentLightIndex < 3) {
        self.currentLightIndex++;
    }
    NSLog(@"light index is: %d", self.currentLightIndex);
}

- (void)descreaseLightIndex
{
    if (self.currentLightIndex > 1) {
        self.currentLightIndex--;
    }
    NSLog(@"light index is: %d", self.currentLightIndex);

}

- (void)increaseHue
{
    if (self.currentHue < 60000) {
        self.currentHue += 10000;
    }
    
    if (self.currentSaturation <230) {
        self.currentSaturation +=20;
    }
    
    if (self.currentBrightness <230) {
        self.currentBrightness +=20;
    }
    
    
    [self changeLight1];
    NSLog(@"increase called");
    NSLog(@"current hue: %d", self.currentHue);
    NSLog(@"current brightnes: %d", self.currentBrightness);
    NSLog(@"current saturation: %d", self.currentSaturation);
}

- (void)decreaseHue
{
    if (self.currentHue > 6000) {
        self.currentHue -= 10000;
    }
    
    if (self.currentSaturation >30) {
        self.currentSaturation -=20;
    }
    
    if (self.currentBrightness >30) {
        self.currentBrightness -=20;
    }
    [self changeLight1];
    NSLog(@"decrease called");
    NSLog(@"current hue: %d", self.currentHue);
    NSLog(@"current brightnes: %d", self.currentBrightness);
    NSLog(@"current saturation: %d", self.currentSaturation);


- (void)transitionColor
{
    [self.randomLightsButton setEnabled:NO];
    
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHBridgeSendAPI *bridgeSendAPI = [[PHBridgeSendAPI alloc] init];
    
    for (PHLight *light in cache.lights.allValues) {
        
        PHLightState *lightState = [[PHLightState alloc] init];
        lightState.transitionTime = @250;
        [lightState setHue:[NSNumber numberWithInt:0]];
        [lightState setBrightness:[NSNumber numberWithInt:254]];
        [lightState setSaturation:[NSNumber numberWithInt:254]];
        
        
        
        // Send lightstate to light
        [bridgeSendAPI updateLightStateForId:light.identifier withLightState:lightState completionHandler:^(NSArray *errors) {
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                
                //nslog(@"Response: %@",message);
            }
            
            [self.randomLightsButton setEnabled:YES];
        }];
    }
    
    
}
#pragma mark - Myo 
- (IBAction)cycleLights:(id)sender {
    [self transitionColor];
}

- (void)fistHammer
{
    //Fist in vertical position swinging downward in a hammer like motion
    
    
    //fist is active
    
}

- (void)clearStates
{
    self.xRotation = 0.0;
    self.restActive = NO;
    self.fistActive = NO;
    self.fingersSpreadActive = NO;
}

@end
