//
//  ViewController.h
//  u20_ios_bluetooth_demo
//
//  Created by sb yu on 09/01/2019.
//  Copyright © 2019 sb yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheralDevice;
@property (strong, nonatomic) CBCharacteristic *currReadCharacteristic;
@property (strong, nonatomic) CBCharacteristic *currWriteCharacteristic;
@property (strong, nonatomic) CBService *currService;
@property (strong, nonatomic) IBOutlet UILabel *msgString;

@property (strong, nonatomic) IBOutlet UIButton *btnSearchBLE;
@property (retain, nonatomic) IBOutlet UIButton *btnProtocolTest;

@property (retain, nonatomic) IBOutlet UITableView *tableBLE;
@property (retain) NSMutableArray *listBLE;

@property BOOL isScan;
@property BOOL isConnected;

- (IBAction)fSearchBLE:(id)sender;
- (void)fProtocolTest;

@end

