//
//  NSObject+FrankAutomation.m
//  Frank
//
//  Created by Buckley on 12/5/12.
//
//

#import <objc/runtime.h>

#import <Foundation/Foundation.h>

#import "LoadableCategory.h"

#if !TARGET_OS_IPHONE
#import "FEXTableRow.h"
#import "FEXTableCell.h"
#endif

MAKE_CATEGORIES_LOADABLE(NSObject_FrankAutomation)

#if TARGET_OS_IPHONE

@implementation NSObject (FrankAutomation)

- (NSString *) FEX_accessibilityLabel
{
    NSString* returnValue = nil;
    
    if ([self respondsToSelector: @selector(accessibilityLabel)])
    {
        returnValue = [self accessibilityLabel];
    }
    
    return returnValue;
}

- (CGRect) FEX_accessibilityFrame
{
    CGRect returnValue = CGRectZero;
    
    if ([self respondsToSelector: @selector(accessibilityFrame)])
    {
        returnValue = [self accessibilityFrame];
    }
    
    return returnValue;
}

@end

#else

#import "NSApplication+FrankAutomation.h"

static const NSString* FEX_AccessibilityDescriptionAttribute = @"FEX_AccessibilityDescriptionAttribute";
static const NSString* FEX_ParentAttribute = @"FEX_ParentAttribute";

@implementation NSObject (FrankAutomation)

+ (void) load
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(accessibilitySetOverrideValue:forAttribute:)),
                                   class_getInstanceMethod(self, @selector(FEX_accessibilitySetOverrideValue:forAttribute:)));
}

- (BOOL) FEX_accessibilitySetOverrideValue: (id) value forAttribute: (NSString*) attribute
{
    if ([value isKindOfClass: [NSString class]] && [attribute isEqualToString: NSAccessibilityDescriptionAttribute])
    {
        objc_setAssociatedObject(self, FEX_AccessibilityDescriptionAttribute, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    
    return [self FEX_accessibilitySetOverrideValue: value forAttribute: attribute];
}

- (NSString *) FEX_accessibilityLabel
{
    NSString* returnValue = objc_getAssociatedObject(self, FEX_AccessibilityDescriptionAttribute);
    
    if (returnValue == nil || [returnValue isEqualToString: @""])
    {
        if ([self respondsToSelector: @selector(accessibilityAttributeNames)] &&
            [self respondsToSelector: @selector(accessibilityAttributeValue:)])
        {
            NSArray *candidateAttributes = @[ NSAccessibilityDescriptionAttribute,
                                              NSAccessibilityTitleAttribute ];
            
            for (NSString *candidateAttribute in candidateAttributes)
            {
                if ([[self accessibilityAttributeNames] containsObject: candidateAttribute])
                {
                    id value = [self accessibilityAttributeValue: candidateAttribute];
                                    
                    if ([value isKindOfClass: [NSString class]]) {
                        returnValue = value;
                        break;
                    }
                }
            }
        }
    }
    
    return [[returnValue copy] autorelease];
}

- (void) FEX_setParent: (id) aParent
{
    objc_setAssociatedObject(self, FEX_ParentAttribute, aParent, OBJC_ASSOCIATION_ASSIGN);
}

- (id) FEX_parent
{
    return objc_getAssociatedObject(self, FEX_ParentAttribute);
}

- (CGRect) FEX_accessibilityFrame
{
    NSPoint origin = NSZeroPoint;
    NSSize  size   = NSZeroSize;
    
    NSValue *originValue = nil;
    NSValue *sizeValue   = nil;
    
    CGFloat screenHeight = 0.0;
    CGFloat flippedY     = 0.0;
    
    if ([self respondsToSelector: @selector(accessibilityAttributeNames)] &&
        [self respondsToSelector: @selector(accessibilityAttributeValue:)])
    {
        if ([[self accessibilityAttributeNames] containsObject: NSAccessibilityPositionAttribute])
        {
            originValue = [self accessibilityAttributeValue: NSAccessibilityPositionAttribute];
        }
        
        if ([[self accessibilityAttributeNames] containsObject: NSAccessibilitySizeAttribute])
        {
            sizeValue = [self accessibilityAttributeValue: NSAccessibilitySizeAttribute];
        }
    }
    
    if (originValue != nil) {
        origin = [originValue pointValue];
    }
    
    if (sizeValue != nil)
    {
        size = [sizeValue sizeValue];
    }
    
    for (NSScreen* screen in [NSScreen screens])
    {
        NSRect screenFrame = [screen convertRectFromBacking: [screen frame]];
        screenHeight = MAX(screenHeight, screenFrame.origin.y + screenFrame.size.height);
    }
    
    flippedY = screenHeight - (origin.y + size.height);
    
    if (flippedY >= 0 && originValue != nil)
    {
        origin.y = flippedY;
    }
    
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

- (BOOL) FEX_performAccessibilityAction: (NSString*) anAction
{
    BOOL returnValue = NO;
    
    if ([[self accessibilityActionNames] containsObject: anAction])
    {
        [self accessibilityPerformAction: anAction];
        returnValue = YES;
    }
    
    return returnValue;
}

- (BOOL) FEX_simulateClick
{
    return [self FEX_performAccessibilityAction: NSAccessibilityPressAction];
}

- (BOOL) FEX_raise
{
    return [self FEX_performAccessibilityAction: NSAccessibilityRaiseAction];
}

- (BOOL) FEX_cancel
{
    return [self FEX_performAccessibilityAction: NSAccessibilityCancelAction];
}

- (BOOL) FEX_confirm
{
    return [self FEX_performAccessibilityAction: NSAccessibilityConfirmAction];
}

- (BOOL) FEX_decrement
{
    return [self FEX_performAccessibilityAction: NSAccessibilityDecrementAction];
}

- (BOOL) FEX_delete
{
    return [self FEX_performAccessibilityAction: NSAccessibilityDeleteAction];
}

- (BOOL) FEX_increment
{
    return [self FEX_performAccessibilityAction: NSAccessibilityIncrementAction];
}

- (BOOL) FEX_pick
{
    return [self FEX_performAccessibilityAction: NSAccessibilityPickAction];
}

- (BOOL) FEX_showMenu
{
    return [self FEX_performAccessibilityAction: NSAccessibilityShowMenuAction];
}

@end

@implementation NSWindow(FrankAutomation)

- (CGRect) FEX_accessibilityFrame
{
    CGRect returnValue = NSZeroRect;
    
    if ([self isVisible] && ![self isMiniaturized])
    {
        returnValue = [super FEX_accessibilityFrame];
    }
    
    return returnValue;
}

- (NSArray*) FEX_children
{
    return [NSArray arrayWithObject:[self contentView]];
}

- (id) FEX_parent
{
    return NSApp;
}

@end

@implementation NSControl (FrankAutomation)

- (NSString*) FEX_accessibilityLabel
{
    NSString* returnValue = [super FEX_accessibilityLabel];
    
    if (returnValue == nil || [returnValue isEqualToString: @""])
    {
        returnValue = [[self cell] FEX_accessibilityLabel];
        
        if (returnValue == nil || [returnValue isEqualToString: @""])
        {
            returnValue = [[self cell] title];
        }
    }
    
    return returnValue;
}

- (CGRect) FEX_accessibilityFrame
{
    CGRect returnValue = [[self cell] FEX_accessibilityFrame];
    
    if (NSEqualRects(returnValue, NSZeroRect))
    {
        returnValue = [super FEX_accessibilityFrame];
    }
    
    return returnValue;
}

- (BOOL) FEX_performAccessibilityAction: (NSString*) anAction
{
    BOOL returnValue = [[self cell] FEX_performAccessibilityAction: anAction];
    
    if (returnValue == NO)
    {
        returnValue = [super FEX_performAccessibilityAction: anAction];
    }
    
    return returnValue;
}

@end

@implementation NSMenu (FrankAutomation)

- (NSArray*) FEX_children
{
    return [self itemArray];
}

- (id) FEX_parent
{
    return NSApp;
}

@end

@implementation NSMenuItem (FrankAutomation)

- (NSString*) FEX_accessibilityLabel
{
    NSString* returnValue = nil;
    
    if ([self isSeparatorItem])
    {
        returnValue = @"Separator";
    }
    else
    {
        returnValue = [super FEX_accessibilityLabel];
        
        if (returnValue == nil)
        {
            returnValue = [self title];
        }
    }
    
    return returnValue;
}

- (CGRect) FEX_accessibilityFrame
{
    CGRect         returnValue = NSMakeRect(0, 0, 0, 0);
    NSDictionary*  menuDict    = nil;
    
    if ([[self menu] isEqual: [[NSApplication sharedApplication] mainMenu]])
    {
        
        AXUIElementRef app  = AXUIElementCreateApplication([[NSRunningApplication currentApplication] processIdentifier]);
        AXUIElementRef menu = NULL;
        
        AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute, (CFTypeRef*) &menu);
        
        menuDict = FEX_DictionaryForAXMenu(menu);
    }
    else
    {
        NSValue* menuPointer = [NSValue valueWithPointer: [self menu]];
        menuDict = [[[NSApplication sharedApplication] FEX_axMenus] objectForKey: menuPointer];
    }
    
    if (menuDict != NULL)
    {
        returnValue = [[menuDict objectForKey: [self title]] rectValue];
    }
    
    return returnValue;
}

- (BOOL) FEX_simulateClick
{
    BOOL returnValue = NO;
    
    if ([self menu] != nil)
    {
        if ([self hasSubmenu])
        {
            returnValue = [super FEX_simulateClick];
        }
        else
        {
            NSInteger itemIndex = [[self menu] indexOfItem: self];
            
            if (itemIndex >= 0)
            {
                [[self menu] performActionForItemAtIndex: itemIndex];
                returnValue = YES;
            }
        }
    }
    
    return returnValue;
}

- (NSArray*) FEX_children
{
    NSMutableArray *children = [NSMutableArray array];
    
    NSMenu *submenu = [self submenu];
    
    if (submenu != nil) {
        [children addObject:submenu];
    }
    
    return children;
}

- (id) FEX_parent
{
    id parent = [self parentItem];
    
    if (parent == nil)
    {
        parent = NSApp;
    }
    
    return parent;
}

@end

@implementation NSView (FrankAutomation)

- (BOOL) FEX_raise
{
    return [[self window] FEX_raise];
}

- (BOOL) FEX_simulateClick
{
    BOOL returnValue = [super FEX_simulateClick];
    
    if (!returnValue)
    {
        returnValue = [[self window] makeFirstResponder: nil];
        
        if (returnValue)
        {
            [[self window] makeKeyWindow];
            returnValue = [[self window] makeFirstResponder: self];
        }
    }
    
    return returnValue;
}

- (BOOL) FEX_mouseDownX: (CGFloat) x y: (CGFloat) y
{
    BOOL returnValue = NO;
    
    CGPoint location = CGPointMake(x, y);
    
    CGEventRef event = CGEventCreateMouseEvent(NULL,
                                               kCGEventLeftMouseDown,
                                               location,
                                               kCGMouseButtonLeft);

    if (event != NULL)
    {
        CGEventPost(kCGSessionEventTap, event);
        CFRelease(event);
        event = NULL;
        
        returnValue = YES;
    }
    
    return returnValue;
}

- (BOOL) FEX_dragToX: (CGFloat) x y: (CGFloat) y
{
    BOOL returnValue = NO;
    
    CGPoint location = CGPointMake(x, y);
    
    CGEventRef event = CGEventCreateMouseEvent(NULL,
                                               kCGEventLeftMouseDragged,
                                               location,
                                               kCGMouseButtonLeft);
    if (event != NULL)
    {            
        CGEventPost(kCGSessionEventTap, event);
        CFRelease(event);
        event = NULL;
        
        returnValue = YES;
    }

    return returnValue;
}

- (BOOL) FEX_mouseUpX: (CGFloat) x y: (CGFloat) y
{
    BOOL returnValue = NO;
    
    CGPoint location = CGPointMake(x, y);
    
    CGEventRef event = CGEventCreateMouseEvent(NULL,
                                               kCGEventLeftMouseUp,
                                               location,
                                               kCGMouseButtonLeft);
    if (event != NULL)
    {
        CGEventPost(kCGSessionEventTap, event);
        CFRelease(event);
        event = NULL;
        
        returnValue = YES;
    }
    
    return returnValue;
}

- (CGRect) FEX_accessibilityFrame
{
    CGRect returnValue = [super FEX_accessibilityFrame];
    CGRect visibleRect = [self visibleRect];
    
    returnValue.size.width = visibleRect.size.width;
    returnValue.size.height = visibleRect.size.height;
    
    return returnValue;
}

- (NSArray*) FEX_children
{
    NSArray* subviews = [[self subviews] mutableCopy];
    NSMutableArray* children = [NSMutableArray array];
    
    for (NSView* subview in subviews)
    {
        CGRect frame = [subview FEX_accessibilityFrame];
        
        if (frame.size.width > 0 && frame.size.height > 0)
        {
            [children addObject: subview];
        }
    }
    
    return children;
}

- (id) FEX_parent
{
    id parent = [super FEX_parent];
    
    if (parent == nil)
    {
        parent = [self superview];
    }
    
    if (parent == nil)
    {
        parent = [self window];
    }
}

@end

@implementation NSTableView (FrankAutomation)

- (NSArray*) FEX_children
{
    NSMutableArray* children = [NSMutableArray array];
    
    if ([self headerView] != nil)
    {
        for (NSTableColumn* column in [self tableColumns])
        {
            CGRect frame = [column FEX_accessibilityFrame];
            
            if (frame.size.width > 0 && frame.size.height > 0)
            {
                [children addObject: column];
            }
        }
    }
    
    CGRect visibleRect = [self visibleRect];
    NSRange rowRange = [self rowsInRect: visibleRect];
    
    for (NSUInteger rowNum = rowRange.location; rowNum < rowRange.length; ++rowNum)
    {
        CGRect rowRect = [self rectOfRow: rowNum];
        rowRect = NSIntersectionRect(rowRect, visibleRect);
        
        FEXTableRow* row = [[[FEXTableRow alloc] initWithFrame: rowRect
                                                         table: self] autorelease];
        
        for (NSUInteger colNum = 0; colNum < [self numberOfColumns]; ++colNum)
        {
            CGRect objectFrame = [self frameOfCellAtColumn: colNum row: rowNum];
            objectFrame = NSIntersectionRect(objectFrame, visibleRect);
            
            id cellValue = [self viewAtColumn: colNum
                                                           row: rowNum
                                               makeIfNecessary: NO];
            
            if (cellValue != nil)
            {
                if (colNum == 0)
                {
                    [children addObject: [cellValue superview]];
                }
            }
            else
            {
                // We need to wrap the NSTableView cell in an object to
                // be accessible to Frank.
                
                id<NSTableViewDataSource> dataSource = [self dataSource];
                
                if (dataSource != nil)
                {
                    cellValue = [dataSource tableView: self
                            objectValueForTableColumn: colNum
                                                  row: rowNum];
                }
                else
                {
                    NSTableColumn* column = [[self tableColumns] objectAtIndex: colNum];
                    NSDictionary* bindingInfo = [column infoForBinding: NSValueBinding];
                    NSString* observedKey = [bindingInfo objectForKey: NSObservedKeyPathKey];
                    id observedObject = [bindingInfo objectForKey: NSObservedObjectKey];
                    
                    for (NSString* component in [observedKey componentsSeparatedByString: @"."])
                    {
                        if (cellValue == nil)
                        {
                            cellValue = [observedObject valueForKey: component];
                        }
                        else
                        {
                            if ([cellValue isKindOfClass: [NSArray class]])
                            {
                                cellValue = [[cellValue objectAtIndex: rowNum] valueForKey: component];
                            }
                            else
                            {
                                cellValue = [cellValue valueForKey: component];
                            }
                        }
                    }
                }
                
                if (cellValue != nil)
                {
                    FEXTableCell* cell = [[FEXTableCell alloc] initWithFrame: objectFrame
                                                                         row: row
                                                                       value: cellValue];
                    
                    if (objectFrame.size.width > 0 && objectFrame.size.height > 0)
                    {
                        [row addSubview: cell];
                    }
                    
                    [cell release];
                }
                
                if (row != nil && colNum == 0)
                {
                    [children addObject: row];
                }
            }
        }
    }
    
    return children;
}

@end

@implementation NSTableColumn (FrankAutomation)

- (NSString*) FEX_accessibilityLabel
{
    NSString* returnValue = [super FEX_accessibilityLabel];
    
    if (returnValue == nil || [returnValue isEqualToString: @""])
    {
        returnValue = [[self headerCell] FEX_accessibilityLabel];
        
        if (returnValue == nil || [returnValue isEqualToString: @""])
        {
            returnValue = [[self headerCell] stringValue];
        }
    }
    
    return returnValue;
}

- (CGRect) FEX_accessibilityFrame
{
    NSTableHeaderView* headerView = [[self tableView] headerView];
    CGRect enclosingFrame = [[[headerView tableView] enclosingScrollView] visibleRect];
    CGRect headerFrame = [headerView frame];
    NSUInteger colNum = [[[self tableView] tableColumns] indexOfObject: self];
    CGRect columnFrame = [[self tableView] rectOfColumn: colNum];
    
    headerFrame.origin.x = columnFrame.origin.x;
    headerFrame.size.width = columnFrame.size.width;
    
    headerFrame = NSIntersectionRect(headerFrame, enclosingFrame);
    
    CGRect accessibilityFrame = [headerView convertRect: headerFrame toView: nil];
    accessibilityFrame = [[headerView window] convertRectToScreen: accessibilityFrame];
    
    CGFloat screenHeight = 0;
    
    for (NSScreen* screen in [NSScreen screens])
    {
        NSRect screenFrame = [screen convertRectFromBacking: [screen frame]];
        screenHeight = MAX(screenHeight, screenFrame.origin.y + screenFrame.size.height);
    }
    
    CGFloat flippedY = screenHeight - (accessibilityFrame.origin.y + accessibilityFrame.size.height);
    
    if (flippedY >= 0)
    {
        accessibilityFrame.origin.y = flippedY;
    }
    
    return accessibilityFrame;
}

@end

#endif
