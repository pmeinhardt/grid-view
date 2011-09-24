//
//  DemoAppDelegate.h
//  Demo
//
//  Created by Paul Meinhardt on 9/24/11.
//

#import <UIKit/UIKit.h>


@class DemoViewController;

@interface DemoAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet DemoViewController *viewController;

@end
