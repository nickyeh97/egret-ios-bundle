#import <Foundation/Foundation.h>

@interface VersionFile : NSObject {
@public
    NSString*               version;
    NSMutableDictionary*    group;
}

- (void) parse:(NSData*) jsonData;
- (NSString*) stringify;

@end
