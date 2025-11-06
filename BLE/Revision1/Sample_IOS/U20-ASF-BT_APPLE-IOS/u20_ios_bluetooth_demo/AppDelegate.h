//
//  AppDelegate.h
//  u20_ios_bluetooth_demo
//
//  Created by sb yu on 09/01/2019.
//  Copyright © 2019 sb yu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

