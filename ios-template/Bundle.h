#import <Foundation/Foundation.h>

@interface Bundle : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) NSString* hashId;
@property (nonatomic) NSString* path;
@property (nonatomic) NSString* url;
@property (nonatomic) NSMutableArray<NSString*>* dependencies;

- (id) ToDict;
- (NSString *)ToJSON;

@end
