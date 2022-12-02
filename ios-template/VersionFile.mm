#import "VersionFile.h"
#import "Bundle.h"

@implementation VersionFile 

- (instancetype)init {
	if (self = [super init]) {
		version = @"0.0.0";
        group = [NSMutableDictionary new];
	}
	return self;
}

- (void) parse:(NSData*) jsonData {
    NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSDictionary *bundles = dict[@"group"];
    // NSLog(@"group: %@", bundles);
    [bundles enumerateKeysAndObjectsUsingBlock:^(NSString* key, id obj, BOOL* stop){
        Bundle *_bundle = [[Bundle alloc] init];
        _bundle.name = [obj objectForKey: @"name"];
        _bundle.hashId = [obj objectForKey: @"hash"];
        _bundle.path = [obj objectForKey: @"path"];
        _bundle.url = [obj objectForKey: @"url"];
        _bundle.dependencies = [obj objectForKey: @"dependencies"];

		// NSLog(@"_bundle: %@", _bundle);
        [group setValue:_bundle forKey:key];
		// NSLog(@"group: %@", group);
    }];

    version = dict[@"version"];
}

-(NSString*) stringify {
	// Bundles of group need to transfer to dictionary datatype 
    NSMutableDictionary *_bundles = [NSMutableDictionary new];
    NSArray *keys =[group allKeys];
    for(int i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        Bundle *_bundle = [group objectForKey:key];
        _bundles[key] = [_bundle ToDict];
    }
    // Let version file transfer to dictionary with tree structure 
    NSDictionary *selfDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                          version, @"version", _bundles, @"group", nil];
    
    NSLog(@"Stringify : %@", selfDict);
    // dictionary --> jsonString
	if ([NSJSONSerialization isValidJSONObject:selfDict]) {
		NSError *error; 
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:selfDict options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
	}
	NSLog(@"ERROR: stringify failed !");
	return nil;
}
@end
