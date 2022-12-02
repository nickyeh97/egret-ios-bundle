#import <UIKit/UIKit.h>
#import "Bundle.h"

@interface VersionManager: NSObject

- (instancetype)init;
- (void)downloadRemoteVersion:(NSString*)url success:(void(^)())success;
- (void)save:(NSData*) data;
- (Boolean)read;
- (Bundle*)getBundle:(NSString*) key;
- (NSMutableArray<Bundle*>*)getBundleArray:(NSString*)bundleName;
- (bool) canUpdateSystem;
- (bool) canUpdateBundle:(NSString*) name;
- (void) setBundle:(NSString*) key;

@end
