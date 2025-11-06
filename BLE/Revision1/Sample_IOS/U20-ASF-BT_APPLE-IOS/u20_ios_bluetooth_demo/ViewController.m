//
//  ViewController.m
//  u20_ios_bluetooth_demo
//
//  Created by sb yu on 09/01/2019.
//  Copyright © 2019 sb yu. All rights reserved.
//

#import "ViewController.h"
#import "ProtocolTestViewController.h"

#define CELL_BLE @"CELL"

@interface ViewController ()

@end

@implementation ViewController

@synthesize centralManager;
@synthesize peripheralDevice;
@synthesize currReadCharacteristic;
@synthesize currWriteCharacteristic;
@synthesize currService;

@synthesize msgString;
@synthesize btnSearchBLE;

@synthesize tableBLE;
@synthesize listBLE;

@synthesize isScan;
@synthesize isConnected;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setTitle:@"SecuGen Unity20BT BLE Demo"];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    self.listBLE = [[NSMutableArray alloc] init];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.peripheralDevice = [CBPeripheral alloc];
    self.currWriteCharacteristic = [CBCharacteristic alloc];
    self.currReadCharacteristic = [CBCharacteristic alloc];
    self.currService = [CBService alloc];
    self.isScan = false;
    self.isConnected = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.tableBLE release];
    [self.listBLE release];
    [super dealloc];
}

//=============================================================================================================================================
// Table
//=============================================================================================================================================
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return nil;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableBLE) {

        if (nil == self.listBLE)
            return 0;

        return [self.listBLE count];
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableBLE) {
        if (nil == self.listBLE)
            return 0;

        return [self.listBLE count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableBLE) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_BLE];
        if (nil == cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_BLE]autorelease];
        }
        
        cell.textLabel.text = ((CBPeripheral*)[self.listBLE objectAtIndex:indexPath.row]).name;
        return cell;
    }
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableBLE) {
        CBPeripheral *peripheral = [self.listBLE objectAtIndex:indexPath.row];
        switch (peripheral.state) {
            case CBPeripheralStateConnecting: {
                NSLog(@"State connecting");
                break;
            }
            case CBPeripheralStateConnected:
            {
                NSLog(@"%@ already connected",peripheral.name);
                NSLog(@"%@ testing....", self.peripheralDevice.name);
                [self fProtocolTest];
                
                break;
            }
            case CBPeripheralStateDisconnecting: {
                NSLog(@"State disconnecting");
                break;
            }
            case CBPeripheralStateDisconnected: {
                self.peripheralDevice = [peripheral copy];
                self.peripheralDevice.delegate = self;
                
                [self.centralManager connectPeripheral:self.peripheralDevice options:nil];
                NSLog(@"Try to connect device...");
                
                break;
            }
            default:
                break;
        }
    }
}

//=============================================================================================================================================
// self functions
//=============================================================================================================================================
- (IBAction)fSearchBLE:(id)sender {
    
    if (self.isScan == false) {
        NSLog(@"centralManager.state=%ld", centralManager.state);
        if (centralManager.state == CBManagerStatePoweredOn){
            if (self.isConnected) {
                // disconnect
                [self.centralManager cancelPeripheralConnection:self.peripheralDevice];
            }
            
            NSLog(@"Start Search");
            [self.listBLE removeAllObjects];
            [self.tableBLE reloadData];
            //[centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"0xAAAA"]] options:nil];
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            self.isScan = true;
        } else {
            [self ShowBluetoothSettingAlert];
        }
    } else {
        [self.centralManager stopScan];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.isScan = false;
        //[self.peripheralDevice release];
    }
}

- (void)fProtocolTest {
    if (self.isConnected) {

        // method - 0
        ProtocolTestViewController *PTVC = [[ProtocolTestViewController alloc]init];
        PTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"UNITY20BT_PROTOCOL"];
        PTVC.peripheralDevice = self.peripheralDevice;
        PTVC.devWriteCharacteristic = self.currWriteCharacteristic;
        PTVC.devReadCharacteristic = self.currReadCharacteristic;
        PTVC.devService = self.currService;
        [self.navigationController pushViewController:PTVC animated:YES];
        
    } else {
        NSLog(@"Require must be connect Unity20BT");
    }
}

//=============================================================================================================================================
// CentralManater
//=============================================================================================================================================
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStateUnknown:
            break;
        case CBManagerStateResetting:
            break;
        case CBManagerStateUnsupported:
            break;
        case CBManagerStateUnauthorized:
            break;
        case CBManagerStatePoweredOff:
            break;
        case CBManagerStatePoweredOn:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    NSString *name = [peripheral.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (name != nil) {
        NSLog(@"insert Name %@", name);
        [self.listBLE addObject:peripheral];
        [self.tableBLE reloadData];
        
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%@ connection success",peripheral.name);
    self.isConnected = true;
    
    [self.centralManager stopScan];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.isScan = false;
    
    [self.peripheralDevice discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%@ disconnect success",peripheral.name);
    [self.peripheralDevice release];
    [self.listBLE removeObject:peripheral];
    [self.tableBLE reloadData];
    
    self.isConnected = false;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%@ connection fail",peripheral.name);
    //[peripherals removeObject:peripheral];
}

//=============================================================================================================================================
// PeripheralManater
//=============================================================================================================================================
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"discoverServices");
    for (CBService *service in peripheral.services) {
        // select SecuGen's BLE Module
        if ([self containsService:service]) {
            NSLog(@"service copy...%@", service.UUID.UUIDString);
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (Boolean)containsService:(CBService *)service {
    NSLog(@"containsService");
    if ([UUID_SG_SERVICE_PREFIX isEqualToString:service.UUID.UUIDString]) {
        return YES;
    }
    return NO;
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"discovercharacteristicsforservice");
    
    CBMutableCharacteristic *readcharacteristic = (CBMutableCharacteristic *)[service.characteristics objectAtIndex:0]; // UUID_SG_CHARACTERISTICS_READ
    CBMutableCharacteristic *writecharacteristic = (CBMutableCharacteristic *)[service.characteristics objectAtIndex:1]; // UUID_SG_CHARACTERISTICS_WRITE
    
    self.currWriteCharacteristic = writecharacteristic;
    self.currReadCharacteristic = readcharacteristic;
    self.currService = service;
    
    NSLog(@"%@ testing....", self.peripheralDevice.name);
    
    // show protocoltest viewcontroller
    [self fProtocolTest];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic.isNotifying) {
        NSLog(@"View Controller - Notification began on %@", characteristic);
    } else {
        // Notification has stopped
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

@end
