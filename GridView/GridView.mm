//
//  GridView.m
//  Booklets
//
//  Created by Paul Meinhardt on 9/20/11.
//

#import "GridView.h"


@interface GridView ()
- (void)setup;
- (void)clear;
- (void)reuse:(GridViewCell *)cell;
- (void)renegotiate;
- (void)recalc;

- (NSArray *)visibleIndexPaths;
- (CGRect)frameForCellAtIndexPath:(GridViewIndexPath *)indexPath;

- (void)layoutVisibleCells;
- (GridViewCell *)loadVisibleCellAtIndexPath:(GridViewIndexPath *)indexPath;
- (void)displayCell:(GridViewCell *)cell atIndexPath:(GridViewIndexPath *)indexPath;

- (void)selected:(UITapGestureRecognizer *)recognizer;
@end


@implementation GridView

@synthesize delegate = _deleg;
@synthesize datasource = _datasource;

@synthesize sectionPadding = _sectionPadding;
@synthesize cellSpacing = _cellSpacing;
@synthesize cellSize = _cellSize;

#pragma mark Initialization

- (void)setup
{
    [self setAlwaysBounceVertical:YES];
    [self setDelaysContentTouches:YES];
    [self setCanCancelContentTouches:YES];
    
    _sectionPadding = CGSizeMake(4.0, 4.0);
    _cellSpacing = CGSizeMake(4.0, 4.0);
    _cellSize = CGSizeMake(75.0, 75.0);
    
    _selectionRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selected:)];
    [self addGestureRecognizer:_selectionRecognizer];
    
    _reusableCells = [[NSMutableDictionary alloc] init];
    _visibleCells = [[NSMutableDictionary alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark Refreshing content

- (void)clear
{
    NSArray *indexPaths = [self visibleIndexPaths];
    GridViewCell *cell;
    
    for (GridViewIndexPath *indexPath in indexPaths) {
        cell = [self cellForItemAtIndexPath:indexPath];
        if (cell) {
            [self reuse:cell];
        }
    }
    
    [_visibleCells removeAllObjects];
}

- (void)reload
{
    [self clear];
    [self renegotiate];
    [self recalc];
    [self setNeedsLayout];
}

#pragma mark Caching

- (void)renegotiate
{
    _flags.delegateWillDisplayCell = [self.delegate respondsToSelector:@selector(gridView:willDisplayCell:forItemAtIndexPath:)];
    
    _flags.datasourceNumberOfSections = [self.datasource respondsToSelector:@selector(numberOfSectionsInGridView:)];
    _flags.datasourceHeightForHeader = [self.datasource respondsToSelector:@selector(gridView:heightForHeaderInSection:)];
    _flags.datasourceHeightForFooter = [self.datasource respondsToSelector:@selector(gridView:heightForFooterInSection:)];
    _flags.datasourceViewForHeader = [self.datasource respondsToSelector:@selector(gridView:viewForHeaderInSection:)];
    _flags.datasourceViewForFooter = [self.datasource respondsToSelector:@selector(gridView:viewForFooterInSection:)];
}

- (GridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)reuseIdentifier
{
    if (!reuseIdentifier) {
        return nil;
    }
    
    NSMutableSet *set = [_reusableCells objectForKey:reuseIdentifier];
    GridViewCell *cell = [set anyObject];
    
    if (cell) {
        [cell retain]; // otherwise retain count drops to 0 in next instruction
        [set removeObject:cell];
    }
    
    return [cell autorelease];
}

- (void)reuse:(GridViewCell *)cell
{
    NSString *identifier = cell.reuseIdentifier;
    NSMutableSet *set = [_reusableCells objectForKey:identifier];
    if (set) {
        [set addObject:cell];
    } else {
        set = [NSMutableSet setWithObject:cell];
        [_reusableCells setObject:set forKey:identifier];
    }
    [cell removeFromSuperview];
}

- (GridViewCell *)cellForItemAtIndexPath:(GridViewIndexPath *)indexPath
{
    return [_visibleCells objectForKey:indexPath];
}

#pragma mark Layout calculation

- (void)recalc
{
    CGFloat overall = 0.0;
    NSUInteger items;
    NSUInteger rows;
    CGFloat height;
    CGFloat width;
    
    if (_flags.datasourceNumberOfSections) {
        _sections = [self.datasource numberOfSectionsInGridView:self];
    } else {
        _sections = 1;
    }
    
    _columns = 1;
    
    width = (2 * self.sectionPadding.width) + self.cellSize.width;
    while (width + self.cellSpacing.width + self.cellSize.width <= self.bounds.size.width) {
        width += self.cellSpacing.width + self.cellSize.width;
        _columns++;
    }
    
    _itemCounts.clear();
    _itemCounts.reserve(_sections);
    
    _offsets.clear();
    _offsets.reserve(3 * _sections + 1);
    
    for (NSUInteger section = 0; section < _sections; section++) {
        
        // _offsets[i + 0] = header offset of section i
        _offsets.push_back(overall);
        
        if (_flags.datasourceHeightForHeader) {
            overall += [self.datasource gridView:self heightForHeaderInSection:section];
        }
        
        // _offsets[i + 1] = content offset of section i
        _offsets.push_back(overall);
        
        items = [self.datasource gridView:self numberOfItemsInSection:section];
        _itemCounts.push_back(items);
        
        rows = items / _columns + ((items % _columns > 0)? 1 : 0);
        height = 2 * self.sectionPadding.height;
        height += rows * self.cellSize.height + (rows-1) * self.cellSpacing.height;
        
        overall += height;
        
        // _offsets[i + 2] = footer offset of section i
        _offsets.push_back(overall);
        
        if (_flags.datasourceHeightForFooter) {
            overall += [self.datasource gridView:self heightForFooterInSection:section];
        }
    }
    
    // _offsets[3 * _sections + 1] = overall height
    _offsets.push_back(overall);
    
    [self setContentSize:CGSizeMake(self.bounds.size.width, overall)];
}

- (CGFloat)heightForHeaderInSection:(NSUInteger)section
{
    if (section + 1 < _offsets.size()) {
        // section content offset - header offset
        return _offsets[section+1] - _offsets[section];
    }
    return 0.0;
}

- (CGFloat)heightForContentInSection:(NSUInteger)section
{
    if (section + 2 < _offsets.size()) {
        // section footer offset - content offset
        return _offsets[section+2] - _offsets[section+1];
    }
    return 0.0;
}

- (CGFloat)heightForFooterInSection:(NSUInteger)section
{
    if (section + 3 < _offsets.size()) {
        // next section's header offset - footer offset
        return _offsets[section+3] - _offsets[section+2];
    }
    return 0.0;
}

- (NSArray *)visibleIndexPaths
{
    CGRect visibleBounds = { self.contentOffset, self.bounds.size };
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    CGRect frame;
    
    GridViewIndexPath *indexPath = [[GridViewIndexPath alloc] initWithIndex:0 section:0];
    
    for (NSUInteger section = 0; section < _sections; section++) {
        for (NSUInteger index = 0; index < _itemCounts[section]; index++) {
            [indexPath setSection:section];
            [indexPath setIndex:index];
            
            frame = [self frameForCellAtIndexPath:indexPath];
            if (CGRectIntersectsRect(frame, visibleBounds)) {
                [indexPaths addObject:[[indexPath copy] autorelease]];
            } else if (CGRectGetMinY(frame) > CGRectGetMaxY(visibleBounds)) {
                break;
            }
        }
    }
    
    [indexPath release];
    
    return [indexPaths autorelease];
}

- (GridViewIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    NSArray *visiblePaths = [self visibleIndexPaths];
    
    for (GridViewIndexPath *indexPath in visiblePaths) {
        if (CGRectContainsPoint([self frameForCellAtIndexPath:indexPath], point)) {
            return indexPath;
        }
    }
    
    return nil;
}

- (CGRect)frameForCellAtIndexPath:(GridViewIndexPath *)indexPath
{
    CGRect frame = CGRectMake(0.0, 0.0, self.cellSize.width, self.cellSize.height);
    
    NSUInteger section = [indexPath section];
    NSUInteger index = [indexPath index];
    
    CGFloat x = self.sectionPadding.width;
    CGFloat y = self.sectionPadding.height + _offsets[section+1];
    
    NSUInteger row = index / _columns;
    NSUInteger column = index - (row * _columns);
    
    x += column * (_cellSize.width + _cellSpacing.width);
    y += row * (_cellSize.height + _cellSpacing.height);
    
    frame.origin.x = x;
    frame.origin.y = y;
    
    return frame;
}

#pragma mark Layouting

- (void)layoutSubviews
{
    [self layoutVisibleCells];
    [super layoutSubviews];
}

- (void)layoutVisibleCells
{
    NSArray *visiblePaths = [self visibleIndexPaths];
    
    for (GridViewIndexPath *indexPath in visiblePaths) {
        GridViewCell *cell = [self cellForItemAtIndexPath:indexPath];
        if (!cell) {
            cell = [self loadVisibleCellAtIndexPath:indexPath];
            [self displayCell:cell atIndexPath:indexPath];
        }
    }
    
    NSArray *paths = [_visibleCells allKeys];
    
    for (GridViewIndexPath *indexPath in paths) {
        if (![visiblePaths containsObject:indexPath]) {
            [self reuse:[self cellForItemAtIndexPath:indexPath]];
            [_visibleCells removeObjectForKey:indexPath];
        }
    }
}

- (GridViewCell *)loadVisibleCellAtIndexPath:(GridViewIndexPath *)indexPath
{
    GridViewCell *cell = [self.datasource gridView:self cellForItemAtIndexPath:indexPath];
    [_visibleCells setObject:cell forKey:indexPath];
    return cell;
}

- (void)displayCell:(GridViewCell *)cell atIndexPath:(GridViewIndexPath *)indexPath
{
    [cell setFrame:[self frameForCellAtIndexPath:indexPath]];
    
    if ([self.delegate respondsToSelector:@selector(gridView:willDisplayCell:forItemAtIndexPath:)]) {
        [self.delegate gridView:self willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    
    [self addSubview:cell];
    [self sendSubviewToBack:cell];
}

#pragma mark Interacting

- (void)selected:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    GridViewIndexPath *indexPath = [self indexPathForItemAtPoint:point];
    
    if (!indexPath) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(gridView:willSelectItemAtIndexPath:)]) {
        [self.delegate gridView:self willSelectItemAtIndexPath:indexPath];
    }
    
    if ([self.delegate respondsToSelector:@selector(gridView:didSelectItemAtIndexPath:)]) {
        [self.delegate gridView:self didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark Setters

- (void)setDelegate:(id<GridViewDelegate>)delegate
{
    _deleg = delegate;
    [self renegotiate];
}

- (void)setDatasource:(id<GridViewDataSource>)datasource
{
    _datasource = datasource;
    [self reload];
}

- (void)setSectionPadding:(CGSize)sectionPadding
{
    if (!CGSizeEqualToSize(sectionPadding, _sectionPadding)) {
        _sectionPadding = sectionPadding;
        [self reload];
    }
}

- (void)setCellSpacing:(CGSize)cellSpacing
{
    if (!CGSizeEqualToSize(cellSpacing, _cellSpacing)) {
        _cellSpacing = cellSpacing;
        [self reload];
    }
}

- (void)setCellSize:(CGSize)cellSize
{
    if (!CGSizeEqualToSize(cellSize, _cellSize)) {
        _cellSize = cellSize;
        [self reload];
    }
}

- (void)setBounds:(CGRect)bounds
{
    CGSize old = self.bounds.size;
    [super setBounds:bounds];
    if (!CGSizeEqualToSize(old, self.bounds.size)) {
        [self reload];
    }
}

- (void)setFrame:(CGRect)frame
{
    CGSize old = self.frame.size;
    [super setFrame:frame];
    if (!CGSizeEqualToSize(old, self.frame.size)) {
        [self reload];
    }
}

#pragma mark Getters

- (NSUInteger)numberOfSections
{
    return _sections;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    return (section < _itemCounts.size())? _itemCounts[section] : 0;
}

#pragma mark Memory management

- (void)dealloc
{
    [_selectionRecognizer release];
    [_reusableCells release];
    [_visibleCells release];
    [super dealloc];
}

@end


#pragma mark -

@implementation GridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    if (self) {
        _reuseIdentifier = reuseIdentifier;
    }
    return self;
}

+ (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    id instance = [[self alloc] initWithReuseIdentifier:reuseIdentifier];
    return [instance autorelease];
}

- (void)dealloc
{
    [_reuseIdentifier release];
    [super dealloc];
}

@end


#pragma mark -

@implementation GridViewIndexPath

@synthesize section = _section;
@synthesize index = _index;

- (id)initWithIndex:(NSUInteger)index section:(NSUInteger)section
{
    self = [super init];
    if (self) {
        _section = section;
        _index = index;
    }
    return self;
}

+ (id)indexPathWithIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    id instance = [[self alloc] initWithIndex:index section:section];
    return [instance autorelease];
}

- (BOOL)isEqual:(id)object
{
    GridViewIndexPath *other = (GridViewIndexPath *)object;
    return (other.index == self.index && other.section == self.section);
}

- (NSUInteger)hash
{
    return (_section << 16) + _index;
}

- (NSComparisonResult)compare:(GridViewIndexPath *)other
{
    if (other.section == _section && other.index == _index) {
        return NSOrderedSame;
    }
    if (other.section > _section) {
        return NSOrderedAscending;
    }
    if (other.section == _section && other.index > _index) {
        return NSOrderedAscending;
    }
    return NSOrderedDescending;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithIndex:_index section:_section];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <section: %i, index: %u>", NSStringFromClass([self class]), _section, _index];
}

@end
