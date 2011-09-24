//
//  DemoViewController.m
//  Demo
//
//  Created by Paul Meinhardt on 9/24/11.
//

#import "DemoViewController.h"


@implementation DemoViewController

@synthesize grid = _grid;

- (void)dealloc
{
    [_grid release];
    [super dealloc];
}

#pragma mark - Grid view delegate

- (void)gridView:(GridView *)gridView willDisplayCell:(GridViewCell *)cell forItemAtIndexPath:(GridViewIndexPath *)indexPath
{
    UILabel *label = (UILabel *)[cell viewWithTag:42];
    [label setText:[NSString stringWithFormat:@"%i", indexPath.index]];
}

#pragma mark - Grid view datasource

- (NSUInteger)gridView:(GridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    return 9999;
}

- (GridViewCell *)gridView:(GridView *)gridView cellForItemAtIndexPath:(GridViewIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"GridCell";
    
    GridViewCell *cell = [gridView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [GridViewCell cellWithReuseIdentifier:cellIdentifier];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 75.0, 75.0)];
        
        [label setBackgroundColor:[UIColor whiteColor]];
        [label setFont:[UIFont fontWithName:@"Helvetica" size:9.0]];
        [label setTextAlignment:UITextAlignmentCenter];
        [label setTag:42];
        
        [cell addSubview:label];
        
        [label release];
    }
    
    return cell;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.grid reload];
}

@end
