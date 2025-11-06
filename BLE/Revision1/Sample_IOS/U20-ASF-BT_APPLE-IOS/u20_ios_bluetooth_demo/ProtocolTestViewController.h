//
//  ProtocolTestViewController.h
//  u20_ios_bluetooth_demo
//
//  Created by sb yu on 15/02/2019.
//  Copyright © 2019 sb yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import <FMSProtocol/FMSProtocol.h>

NS_ASSUME_NONNULL_BEGIN

#define UUID_SG_SERVICE_PREFIX          @"AAAA"
#define UUID_SG_SERVICE                 @"0000AAAA-0000-1000-8000-00805F9B34FB"
#define UUID_SG_CHARACTERISTICS_READ    @"00002BB1-0000-1000-8000-00805F9B34FB"
#define UUID_SG_CHARACTERISTICS_WRITE   @"00002BB2-0000-1000-8000-00805F9B34FB"
#define UUID_SG_CHARACTERISTICS_NOTIFY  @"00002902-0000-1000-8000-00805F9B34FB"

@interface ProtocolTestViewController : UIViewController <CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBPeripheral *peripheralDevice;
@property (strong, nonatomic) CBCharacteristic *devWriteCharacteristic;
@property (strong, nonatomic) CBCharacteristic *devReadCharacteristic;
@property (strong, nonatomic) CBService *devService;

@property (retain, nonatomic) IBOutlet UIButton *btnGetVersion;
@property (retain, nonatomic) IBOutlet UIButton *btnResigt1;
@property (retain, nonatomic) IBOutlet UIButton *btnResigt2;
@property (retain, nonatomic) IBOutlet UIButton *btnVerify;
@property (retain, nonatomic) IBOutlet UIButton *btnIdentify;
@property (retain, nonatomic) IBOutlet UIButton *btnDelete;
@property (retain, nonatomic) IBOutlet UIButton *btnGetImage;
@property (retain, nonatomic) IBOutlet UIButton *btnAutoIdentify;

@property (retain, nonatomic) IBOutlet UISwitch *swFullSize;
@property (retain, nonatomic) IBOutlet UISwitch *swUseWSQ;

@property (retain, nonatomic) IBOutlet UILabel *lbVersion;
@property (retain, nonatomic) IBOutlet UILabel *lbStatus;

@property (retain, nonatomic) IBOutlet UITextField *tfUserID;

@property (retain, nonatomic) IBOutlet UITextView *tvLogViewer;
@property (retain, nonatomic) IBOutlet UITextField *tfSendSize;
@property (retain, nonatomic) IBOutlet UIImageView *ImgViewer;

@property (retain, nonatomic) UIActivityIndicatorView *activityViewer;
@property (strong, atomic) NSMutableData *ImageData;

@property (atomic) uint16_t imgsize;
@property (atomic) uint16_t wsqbitrate;
@property (atomic) uint8_t isWSQ;
@property (atomic) uint8_t isAutoIdentify;
@property (atomic) int regUserID;

- (IBAction)fGetVersion:(id)sender;
- (IBAction)fGetImage:(id)sender;
- (IBAction)fAutoIdentify:(id)sender;
- (IBAction)fRegistStart:(id)sender;
- (IBAction)fRegistEnd:(id)sender;
- (IBAction)fVerify:(id)sender;
- (IBAction)fIdentify:(id)sender;
- (IBAction)fDelete:(id)sender;
- (IBAction)switchEvent:(id)sender;

- (void) sgLog:(NSString *)logmsg;
- (void) FMSProtocolParsing: (uint8_t*) packet;
- (void) FMSProtocolParsingLog:(NSString *)strLog;
- (CGImageRef) createUIImagefromRaw:(unsigned char *)buffer withWidth:(int)width withHeight:(int)height;

@end

NS_ASSUME_NONNULL_END
