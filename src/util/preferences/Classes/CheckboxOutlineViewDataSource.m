#import "CheckboxOutlineViewDataSource.h"
#import "PreferencesWindowController.h"
#import "ServerClient.h"
#import "SharedXMLCompilerTree.h"

@interface FilterCondition : NSObject

@property BOOL isEnabledOnly;
@property(copy) NSString* string;

- (BOOL)isEqualToFilterCondition:(FilterCondition*)other;

@end

@implementation FilterCondition

- (instancetype)init:(BOOL)isEnabledOnly string:(NSString*)string {
  self = [super init];

  if (self) {
    self.isEnabledOnly = isEnabledOnly;
    self.string = string;
  }

  return self;
}

- (BOOL)isEqualToFilterCondition:(FilterCondition*)other {
  if (self.isEnabledOnly != other.isEnabledOnly) {
    return NO;
  }

  if (![self compareString:other.string]) {
    return NO;
  }

  return YES;
}

- (BOOL)compareString:(NSString*)otherString {
  if (self.string == nil && otherString == nil) {
    return YES;
  }
  if (self.string != nil && otherString != nil) {
    return [self.string compare:otherString] == NSOrderedSame;
  }
  return NO;
}

@end

@interface CheckboxOutlineViewDataSource ()

@property(weak) IBOutlet PreferencesWindowController* preferencesWindowController;
@property(weak) IBOutlet ServerClient* client;
@property SharedXMLCompilerTree* dataSource;
@property FilterCondition* filterCondition;

@end

@implementation CheckboxOutlineViewDataSource

- (void)setup {
  self.dataSource = [self.client.proxy sharedCheckboxTree];
  self.filterCondition = nil;
}

// return YES if we need to call [NSOutlineView reloadData]
- (BOOL)filterDataSource:(BOOL)isEnabledOnly string:(NSString*)string {
  // Check filter condition is changed from previous filterDataSource.
  FilterCondition* filterCondition = [[FilterCondition alloc] init:isEnabledOnly string:string];
  if ([self.filterCondition isEqualToFilterCondition:filterCondition]) {
    return NO;
  }

  // ----------------------------------------
  NSMutableArray* strings = [NSMutableArray new];
  if (string) {
    for (NSString* s in [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
      if ([s length] == 0) continue;
      [strings addObject:s];
    }
  }

  if (isEnabledOnly || [strings count] > 0) {
    self.dataSource = [self.client.proxy narrowedSharedCheckboxTree:isEnabledOnly strings:strings];
  } else {
    self.dataSource = [self.client.proxy sharedCheckboxTree];
  }

  self.filterCondition = filterCondition;
  return YES;
}

- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item {
  SharedXMLCompilerTree* tree = (SharedXMLCompilerTree*)(item);
  return tree ? [tree.children count] : [self.dataSource.children count];
}

- (void)clearFilterCondition {
  self.filterCondition = nil;
}

- (id)outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
  SharedXMLCompilerTree* tree = (SharedXMLCompilerTree*)(item);
  NSArray* a = tree ? tree.children : self.dataSource.children;

  if ((NSUInteger)(index) >= [a count]) return nil;
  return a[index];
}

- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item {
  SharedXMLCompilerTree* tree = (SharedXMLCompilerTree*)(item);
  NSArray* a = tree ? tree.children : self.dataSource.children;
  return [a count] > 0;
}

@end