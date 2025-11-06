//
//  ProtocolTestViewController.m
//  u20_ios_bluetooth_demo
//
//  Created by sb yu on 15/02/2019.
//  Copyright © 2019 sb yu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ProtocolTestViewController.h"

static int remaining_data_size = 0;
static int total_receive_size = 0;

@interface ProtocolTestViewController ()

@end


@implementation ProtocolTestViewController

@synthesize peripheralManager;
@synthesize peripheralDevice;
@synthesize devWriteCharacteristic;
@synthesize devReadCharacteristic;
@synthesize devService;

@synthesize swFullSize;
@synthesize swUseWSQ;
@synthesize lbVersion;
@synthesize lbStatus;
@synthesize tfUserID;
@synthesize tvLogViewer;
@synthesize tfSendSize;
@synthesize ImgViewer;
@synthesize activityViewer;

@synthesize ImageData;

@synthesize imgsize;
@synthesize wsqbitrate;
@synthesize isWSQ;
@synthesize isAutoIdentify;
@synthesize regUserID;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setTitle:[NSString stringWithFormat:@"%@", peripheralDevice.name]];
    
    peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    peripheralDevice.delegate = self;
    
    [self.tfUserID setDelegate:self];
    [self.tfSendSize setDelegate:self];
    
    self.swFullSize.on = YES;
    self.swFullSize.tag = 1;
    self.swUseWSQ.on = YES;
    self.swUseWSQ.tag = 2;
    self.imgsize = 1;
    self.isWSQ = 1;
    self.wsqbitrate = 0x0200;
    self.isAutoIdentify = 0;
    self.regUserID = -1;
    
    UIImage* image = [UIImage imageNamed:@"test_finger2"];
    NSAssert(image, @"image is nil. Check that you added the image to your bundle and that the filename above matches the name of you image.");
    self.ImgViewer.backgroundColor = [UIColor blackColor];
    self.ImgViewer.clipsToBounds = YES;
    self.ImgViewer.image = image;
    
    self.ImageData = [[NSMutableData alloc] init];
    
    // ProgressBar Setting
    activityViewer = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    [activityViewer setCenter:self.ImgViewer.center];
    [activityViewer setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityViewer setColor:[UIColor orangeColor]];
    [self.view addSubview : activityViewer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [peripheralDevice setNotifyValue:YES forCharacteristic:devReadCharacteristic];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    NSLog(@"self.peripheralManager powered on.");

    long package_max_size = [peripheralDevice maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse];
    NSLog(@"package_max_size: %ld", package_max_size);
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"Added service %@", [service UUID]);
    if (error) {
        NSLog(@"There was an error adding service");
        NSLog(@"%@", error);
    }
    
    NSDictionary *advertisingData = @{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:UUID_SG_SERVICE]]};
    [self.peripheralManager startAdvertising:advertisingData];
}

- (void) peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"Started advertising");
    if (error) {
        NSLog(@"There was an error advertising");
        NSLog(@"%@", error);
    }
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"didReceiveReadRequest");
    NSLog(@"- UUID: %@",request.characteristic.UUID);
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(CBATTRequest *)request {
    NSLog(@"didReceiveWriteRequests");
    NSLog(@"- UUID: %@",request.characteristic.UUID);
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}


- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

-(void)peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"Notification began on %@", characteristic);
    NSLog(@"- UUID: %@", characteristic.UUID);
    /*
    NSData *receiveData = characteristic.value;
    if ([receiveData length] != 0) {
        Byte *byte = (Byte *)[receiveData bytes];
        
        if ([receiveData length] == PACKET_HEADER_SIZE && (byte[0] == 'n' || byte[0] == 'N')) { // notify from u20-asf-bt
            [self.peripheralDevice readValueForCharacteristic:devReadCharacteristic];
        }
    }
     */
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        [self sgLog:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]]];
        return;
    }
    
    //NSLog(@"didUpdateValueForCharacteristic: %@", characteristic.UUID);
    
    NSData *receiveData = characteristic.value;
    if ([receiveData length] != 0) {
        Byte *byte = (Byte *)[receiveData bytes];
        
        if ([receiveData length] == PACKET_HEADER_SIZE && (byte[0] == 'n' || byte[0] == 'N')) { // notify from u20-asf-bt
            NSLog(@"A notify has occurred in characteristic: %@", characteristic.UUID);
            [self.peripheralDevice readValueForCharacteristic:devReadCharacteristic]; // read receive data
        } else
        {
            if ([receiveData length] == PACKET_HEADER_SIZE) {
                NSString *value = [NSString stringWithFormat:@"receive: %lu bytes, (0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X)", (unsigned long)[receiveData length], byte[0], byte[1], byte[2], byte[3], byte[4], byte[5], byte[6], byte[7], byte[8], byte[9], byte[10], byte[11]];
                [self sgLog:value];
                
                [self FMSProtocolParsing: byte];
            } else {
                [self sgLog:[NSString stringWithFormat:@"readCharactristic receive size: %d", [receiveData length]]];
                
                remaining_data_size -= [receiveData length];
                total_receive_size += [receiveData length];
                NSLog(@"remaining_data_size: %d", remaining_data_size);
                
                if ([receiveData length] != 0)
                    [self.ImageData appendBytes:[receiveData bytes] length:[receiveData length]];
                
                // retry when exist external data
                if (remaining_data_size > 0) {
                    [self.peripheralDevice readValueForCharacteristic:devReadCharacteristic];
                } else {
                    NSLog(@"total_receive_size: %d", total_receive_size);
                    [self sgLog:[NSString stringWithFormat:@"total receive size: %d", total_receive_size]];
                    
                    [activityViewer stopAnimating];
                    activityViewer.hidden= TRUE;
                    
                    int width, height;
                    if (self.imgsize == 1) {
                        width = 300;
                        height = 400;
                    } else {
                        width = 150;
                        height = 200;
                    }
                    
                    unsigned char *imgBuf = nil;
                    if (self.isWSQ) {
                        //imgBuf = (unsigned char*)malloc(width*height+1);
                        
                        int pixelDepth = 0, ppi = 0, lossyFlag = 0;
                        FMSPacket* _packet = [[FMSPacket alloc]init];
                        [_packet getRawBufFromWSQ:&imgBuf withWidth:&width withHeight:&height withPixelDepth:&pixelDepth withPPI:&ppi withLossyFlag:&lossyFlag withWsqBuf:[self.ImageData mutableBytes] withWsqLength:total_receive_size];
                        
                        [self sgLog:[NSString stringWithFormat:@"width: %d, height: %d, pixelDepth: %d, ppi: %d, lossyFlag: %d", width, height, pixelDepth, ppi, lossyFlag]];
                    } else {
                        imgBuf = [self.ImageData mutableBytes];
                    }
                    
                    // getimage command & raw to uiimageview
                    CGImageRef imageRef = [self createUIImagefromRaw:imgBuf withWidth: width withHeight: height];
                    UIImage* uiImage = [[UIImage alloc] initWithCGImage:imageRef];
                    self.ImgViewer.image = uiImage;
                }
                
                [self.tvLogViewer scrollRangeToVisible:NSMakeRange(self.tvLogViewer.text.length, 1)];
                self.tvLogViewer.layoutManager.allowsNonContiguousLayout = NO;
            }
        }
    } else {
        [self sgLog:@"receive 0 byte."];
    }
}

- (void) FMSProtocolParsing: (uint8_t*) packet
{
    FMSPacket* _packet = [[FMSPacket alloc]init];
    uint16_t command = [_packet getCommand:packet];
    uint8_t error = [_packet getError:packet];
    
    if (error == ERR_NONE)
        [self.lbStatus setText: [NSString stringWithFormat:@"Success"]];
    else
        [self.lbStatus setText: [NSString stringWithFormat:@"Error: 0x%02X", error]];
    
    switch (command)
    {
        case CMD_GET_VERSION:
            {
                if (error == ERR_NONE) {
                    [self.lbVersion setText: [NSString stringWithFormat:@"Version: %X.%X", [_packet getParam1: packet], [_packet getParam2:packet]]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"GetVersion failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_GET_IMAGE:
            {
                if (error == ERR_NONE) {
                    remaining_data_size = [_packet getExtendedDataSize: packet];
                    
                    // if exist external data
                    if (remaining_data_size > 0) {
                        
                        activityViewer.hidden= FALSE;
                        [activityViewer startAnimating];
                        
                        self.isWSQ = ([_packet getParam1:packet] & 0xFF00) >> 8;
                        total_receive_size = 0;
                        [self.ImageData setLength:0];
                        [self.peripheralDevice readValueForCharacteristic:devReadCharacteristic];
                    } else {
                        ;
                    }
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"GetImage failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_REGISTER_START:
            {
                if (error == ERR_NONE) {
                    self.regUserID = (int)[_packet getParam1: packet];
                    [self FMSProtocolParsingLog:@"go to register end"];
                } else if (error == ERR_ALREADY_REGISTERED_USER) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X already exist.", [_packet getParam1: packet]]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Register failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_REGISTER_END:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Register success"]];
                    self.regUserID = -1;
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Register failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_DELETE:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X deleted", [_packet getParam1: packet]]];
                } else if (error == ERR_USER_NOT_FOUND) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X not found.", [_packet getParam1: packet]]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Delete failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_VERIFY:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X verified. Score:[ %d ]", [_packet getParam1: packet], [_packet getParam2: packet]]];
                } else if (error == ERR_VERIFY_FAILED) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X not verified. Score: [ %d ]", [_packet getParam1: packet], [_packet getParam2: packet]]];
                } else if (error == ERR_USER_NOT_FOUND) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X not found.", [_packet getParam1: packet]]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Verify failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_IDENTIFY:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User %04X identified. Score:[ %d ]", [_packet getParam1: packet], [_packet getParam2: packet]]];
                } else if (error == ERR_IDENTIFY_FAILED) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"User not found"]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Identify failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_AUTO_IDENTIFY_START:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Success AutoIdentify Started"]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"AutoIdentify Start failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_AUTO_IDENTIFY_STOP:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"Success AutoIdentify Stoped"]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"AutoIdentify Stop failed with Error: 0x%02X", error]];
                }
            }
            break;
        case CMD_FP_AUTO_IDENTIFY:
            {
                if (error == ERR_NONE) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"AutoIdentify User %04X identified. Score:[ %d ]", [_packet getParam1: packet], [_packet getParam2: packet]]];
                } else if (error == ERR_IDENTIFY_FAILED) {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"AutoIdentify User not found."]];
                } else {
                    [self FMSProtocolParsingLog:[NSString stringWithFormat:@"AutoIdentify failed with Error: 0x%02X", error]];
                }
            }
            break;
        default:
            break;
    }
    
    [_packet release];
}

- (void) FMSProtocolParsingLog: (NSString *) strLog
{
    [self sgLog:strLog];
    [self.lbStatus setText:strLog];
}

- (void)dealloc {
    [self.btnGetVersion release];
    [self.tvLogViewer release];
    [self.btnGetImage release];
    [self.tfSendSize release];
    [self.ImgViewer release];
    [self.btnResigt1 release];
    [self.btnResigt2 release];
    [self.btnVerify release];
    [self.btnIdentify release];
    [self.btnDelete release];
    [self.swFullSize release];
    [self.swUseWSQ release];
    [self.lbVersion release];
    [self.lbStatus release];
    [self.tfUserID release];
    [_btnAutoIdentify release];
    [super dealloc];
}

- (IBAction)fGetVersion:(id)sender {
    NSLog(@"get version ");
    
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    uint8_t* valData = [_packet getVersion];
    NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
    [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
    
    [self sgLog:@"get version"];
    
    [_packet release];
}

- (IBAction)fRegistStart:(id)sender {
    NSLog(@"register start ");
    
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    NSInteger nUserID = [self getUserID];
    if (nUserID != -1) {
        uint8_t* valData = [_packet fpRegisterStartWithUserID: (uint16_t)nUserID withMaster: 0];
        NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
        [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        
        [self sgLog:@"register start"];
        
        [_packet release];
    }
}

- (IBAction)fRegistEnd:(id)sender {
    NSLog(@"register start ");
    
    NSInteger nUserID = [self getUserID];
    if ((int)nUserID == self.regUserID) {
        FMSPacket* _packet = [[FMSPacket alloc]init];
        uint8_t* valData = [_packet getPacketWithCommand:CMD_FP_REGISTER_END withParam1:0 withParam2:0 withDataSize:0];
        NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
        [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        
        [self sgLog:@"register end"];
        [_packet release];
    } else if (self.regUserID == -1){
        [self sgLog:@"Please proceed to Regist 1 first."];
    } else {
        [self sgLog:[NSString stringWithFormat:@"User ID is different from the Regist 1(id: %d).", self.regUserID]];
    }
}

- (IBAction)fVerify:(id)sender {
    NSLog(@"verify ");
    
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    NSInteger nUserID = [self getUserID];
    if (nUserID != -1) {
        
        uint8_t* valData = [_packet fpVerifyWithUserID: (uint16_t)nUserID];
        NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
        [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        
        [self sgLog:@"verify"];
        
        [_packet release];
    }
}

- (IBAction)fIdentify:(id)sender {
    NSLog(@"identify ");
    
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    uint8_t* valData = [_packet fpIdentify];
    NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
    [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
    
    [self sgLog:@"identify"];
    
    [_packet release];
}

- (IBAction)fDelete:(id)sender {
    NSLog(@"delete user ");
    
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    NSInteger nUserID = [self getUserID];
    if (nUserID != -1) {
        
        uint8_t* valData = [_packet fpDeleteWithUserID: (uint16_t)nUserID];
        NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
        [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        
        [self sgLog:@"delete user"];
        
        [_packet release];
    }
}

- (IBAction)switchEvent:(id)sender {
    UISwitch *switchObj = (UISwitch*)sender;
    if (switchObj.tag == 1) {
        if (switchObj.on) {
            self.imgsize = 1;
            NSLog(@"image size switch on");
        } else {
            self.imgsize = 2;
            NSLog(@"image size switch off");
        }
    } else if (switchObj.tag == 2) {
        if (switchObj.on) {
            self.wsqbitrate = 0x0200;
            NSLog(@"use wsq switch on");
        } else {
            self.wsqbitrate = 0;
            NSLog(@"use wsq switch off");
        }
    }
}

- (IBAction)fGetImage:(id)sender {
    NSLog(@"get image ");
    
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    uint16_t param1 = self.imgsize | (self.wsqbitrate > 0 ? 0x0100:0);
    uint8_t* valData = [_packet getImageWithParam:param1 withParam2:self.wsqbitrate];
    NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
    [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
    
    [self sgLog:@"get image"];
}

- (IBAction)fAutoIdentify:(id)sender {
    FMSPacket* _packet = [[FMSPacket alloc]init];
    
    if (self.isAutoIdentify == 0) {
        uint8_t* valData = [_packet autoIdentifyStart];
        NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
        [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        [self sgLog:@"AutoIdentify Start"];
        self.isAutoIdentify = 1;
        [self.btnAutoIdentify setTitle:@"Auto Identify Stop" forState:UIControlStateNormal];
    } else {
        uint8_t* valData = [_packet autoIdentifyStop];
        NSData* data = [NSData dataWithBytes:valData length:PACKET_HEADER_SIZE];
        [self.peripheralDevice writeValue:data forCharacteristic:devWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        [self sgLog:@"AutoIdentify Stop"];
        self.isAutoIdentify = 0;
        [self.btnAutoIdentify setTitle:@"Auto Identify Start" forState:UIControlStateNormal];
    }
    
    [_packet release];
}

- (NSInteger) getUserID
{
    NSInteger UserID = 0;
    NSInteger pos = 0;
    unichar szUserID[4] = {0,};
    uint16_t hexValue = 0;
    
    NSUInteger len = [tfUserID.text length];
    if (len % 2 || len != 4) {
        NSLog(@"The User ID must be a 4-digit number.");
        [self sgLog:@"The User ID must be a 4-digit number."];
        return -1;
    } else if (len == 0) {
        NSLog(@"Please enter User ID.");
        [self sgLog:@"Please enter User ID."];
        return -1;
    }
    
    [tfUserID.text getCharacters:szUserID];
    for (NSUInteger i = 0; i < len; i+=2) {
        if ((szUserID[i] > 0x39 || szUserID[i] < 0x30) || (szUserID[i+1] > 0x39 || szUserID[i+1] < 0x30)) {
            NSLog(@"The User ID must be a 4-digit number.");
            [self sgLog:@"The User ID must be a 4-digit number."];
            return -1;
        }
        hexValue = ((hexValue << (pos * 8)) | ((((szUserID[i] - 0x30) << 4) & 0xF0) | ((szUserID[i+1] - 0x30) & 0x0F)));
        pos++;
    }
    
    UserID = hexValue;
    
    return UserID;
}

- (CGImageRef) createUIImagefromRaw:(unsigned char *)buffer withWidth:(int)width withHeight:(int)height {
    
    unsigned char *imageData = buffer;
    size_t imageSize = width * height;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 1;
    size_t bitsPerPixel = bitsPerComponent * bytesPerPixel;
    size_t bytesPerRow = width * bytesPerPixel;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGDataProviderRef providerRef = CGDataProviderCreateWithData(nil, imageData, imageSize, nil);
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    providerRef,    // data provider
                                    NULL,        // decode
                                    NO,            // should interpolate
                                    renderingIntent);
    
    return iref;
}

- (void)sgLog:(NSString *)logmsg {
    if ([@"" isEqualToString:self.tvLogViewer.text]) {
        self.tvLogViewer.text = [NSString stringWithFormat:@"%@", logmsg];
    } else {
        self.tvLogViewer.text = [NSString stringWithFormat:@"%@\n%@",self.tvLogViewer.text, logmsg];
    }
    
    [self.tvLogViewer scrollRangeToVisible:NSMakeRange(self.tvLogViewer.text.length, 1)];
    self.tvLogViewer.layoutManager.allowsNonContiguousLayout = NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(nonnull NSString *)string {
    if (range.length + range.location > textField.text.length) {
        return NO;
    }
    
    NSUInteger newlength = [textField.text length] + [string length] - range.length;
    return newlength <= 4;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    
    if ([[self tfUserID] isFirstResponder]) {
        if ([touch view] != [self tfUserID]) {
            [[self tfUserID] resignFirstResponder];
        }
    }
    
    [super touchesBegan:touches withEvent:event];
}

@end
