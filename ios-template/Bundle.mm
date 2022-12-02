#import "Bundle.h"

@implementation Bundle 
- (instancetype) init {
	if (self = [super init]) {
		self.dependencies = [NSMutableArray arrayWithCapacity:0];
	}
	return self;
}

- (id) ToDict {
	NSDictionary *dict = @{
		@"name":self.name,
		@"hash":self.hashId,
		@"path":self.path,
		@"url":self.url,
		@"dependencies":self.dependencies
	};

   return dict;
}

/**	
	使用 NSJSONSerialization 进行 JSON 解析的前提
	An object that may be converted to JSON must have the following properties:
	(1）顶层对象必须是NSArray或NSDictionary
	(2) 所有对象必须是NSString,NSNumber,NSArray,NSDictionary or NULL
	(3) 所有字典的键值都是字符串类型的
	(4)数值不能是非数值或无穷大
**/
- (NSString *)ToJSON {
	NSDictionary *dict = [self ToDict];
	//whether a given object can be converted to JSON data.
	if ([NSJSONSerialization isValidJSONObject:dict]) {
		NSError *error;
		NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
		NSString *json = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"json data: %@", json);
		return json;
	}
	return nil;
}

@end
