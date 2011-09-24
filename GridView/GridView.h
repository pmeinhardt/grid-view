//
//  GridView.h
//  Booklets
//
//  Created by Paul Meinhardt on 9/20/11.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <vector>
#endif


@class GridView, GridViewCell, GridViewIndexPath;


#pragma mark - Delegate

@protocol GridViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (void)gridView:(GridView *)gridView willDisplayCell:(GridViewCell *)cell forItemAtIndexPath:(GridViewIndexPath *)indexPath;

- (void)gridView:(GridView *)gridView willSelectItemAtIndexPath:(GridViewIndexPath *)indexPath;
- (void)gridView:(GridView *)gridView willDeselectItemAtIndexPath:(GridViewIndexPath *)indexPath;
- (void)gridView:(GridView *)gridView didSelectItemAtIndexPath:(GridViewIndexPath *)indexPath;
- (void)gridView:(GridView *)gridView didDeselectItemAtIndexPath:(GridViewIndexPath *)indexPath;

@end


#pragma mark - Data source

@protocol GridViewDataSource <NSObject>

- (NSUInteger)gridView:(GridView *)gridView numberOfItemsInSection:(NSUInteger)section;
- (GridViewCell *)gridView:(GridView *)gridView cellForItemAtIndexPath:(GridViewIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInGridView:(GridView *)gridView;  // defaults to 1

- (CGFloat)gridView:(GridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(GridView *)gridView heightForFooterInSection:(NSUInteger)section;
- (UIView *)gridView:(GridView *)gridView viewForHeaderInSection:(NSUInteger)section;
- (UIView *)gridView:(GridView *)gridView viewForFooterInSection:(NSUInteger)section;

@end


#pragma mark - Grid view

@interface GridView : UIScrollView {
    UIGestureRecognizer *_selectionRecognizer;
    
    struct {
        unsigned int delegateWillDisplayCell:1;
        unsigned int datasourceNumberOfSections:1;
        unsigned int datasourceHeightForHeader:1;
        unsigned int datasourceHeightForFooter:1;
        unsigned int datasourceViewForHeader:1;
        unsigned int datasourceViewForFooter:1;
    } _flags;
    
    NSUInteger _sections;                   // cached
    NSUInteger _columns;
    
#ifdef __cplusplus
    std::vector<NSUInteger> _itemCounts;
    std::vector<CGFloat> _offsets;          // pre-calculated for optimization
#endif
    
    NSMutableDictionary *_reusableCells;    // cells
    NSMutableDictionary *_visibleCells;
}

@property (nonatomic, assign) IBOutlet id <GridViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id <GridViewDataSource> datasource;

@property (nonatomic, assign) CGSize sectionPadding;
@property (nonatomic, assign) CGSize cellSpacing;
@property (nonatomic, assign) CGSize cellSize;

- (void)reload;

- (GridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)reuseIdentifier;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

- (CGFloat)heightForContentInSection:(NSUInteger)section;
- (CGFloat)heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)heightForFooterInSection:(NSUInteger)section;

- (GridViewCell *)cellForItemAtIndexPath:(GridViewIndexPath *)indexPath;
- (GridViewIndexPath *)indexPathForItemAtPoint:(CGPoint)point;

@end


#pragma mark - Grid view cell

@interface GridViewCell : UIView

@property (nonatomic, copy) NSString *reuseIdentifier;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier;

@end


#pragma mark - Index path

@interface GridViewIndexPath : NSObject <NSCopying>

@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, assign) NSUInteger index;

- (id)initWithIndex:(NSUInteger)index section:(NSUInteger)section;
+ (id)indexPathWithIndex:(NSUInteger)index inSection:(NSUInteger)section;

- (NSComparisonResult)compare:(GridViewIndexPath *)other;

@end
