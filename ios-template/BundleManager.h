#import <Foundation/Foundation.h>
#import "VersionManager.h"

@interface BundleManager : NSObject

- (id) initWithPath:(NSString*) localPath versionMgr:(VersionManager*) versionMgr;
- (void)upgrade:(NSString*) name bundles:(NSArray*) bundles success:(void(^)()) cb;
+ (NSString*)getFileDirByUrl:(NSString*)urlString;

@end
