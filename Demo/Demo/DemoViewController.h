//
//  DemoViewController.h
//  Demo
//
//  Created by Paul Meinhardt on 9/24/11.
//

#import <UIKit/UIKit.h>

#import "GridView.h"

@interface DemoViewController : UIViewController <GridViewDelegate, GridViewDataSource>

@property (nonatomic, retain) IBOutlet GridView *grid;

@end
