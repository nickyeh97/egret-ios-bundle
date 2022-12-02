#import "VersionManager.h"
#import "VersionFile.h"

@implementation VersionManager{
    VersionFile* _loaclVersion;
	VersionFile* _remoteVersion;
	NSString* _localURL;
	NSString* _remoteURL;
	NSFileManager* _fileManager;
}

- (instancetype)init {
	if (self = [super init]) {
		_loaclVersion = [[VersionFile alloc] init];
		_remoteVersion = [[VersionFile alloc] init];
        _fileManager = [NSFileManager defaultManager];
		_remoteURL = @"http://192.168.35.15:5502/bundle/version.json";
		_localURL = @"/localVersion.txt";
        [self locate];
	}
	return self;
}

- (void) locate{
	// https://www.jianshu.com/p/e41e73f4edec
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    _localURL = [docDir stringByAppendingString:_localURL];
    NSLog(@"_localURL : %@", _localURL);
}

// 從 Bundle sever讀取 Bundle 版本表
- (void) downloadRemoteVersion:(NSString*)url success:(void(^)())success {
	if(!url) {
        url = _remoteURL;
	}
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *connectionError) {
        [self->_remoteVersion parse:data];
		NSLog(@"remote version: %@", self->_remoteVersion->version);
    	NSLog(@"remote group: %@", self->_remoteVersion->group);
		if (success) {
			success();
		}
    }] resume];
}

- (void) save:(NSData*) data {
    BOOL isExist = [_fileManager fileExistsAtPath:_localURL];
    NSLog(@"save file: %d", isExist);
	// 創建檔案，假如檔案未存在
    if (!isExist) {
        BOOL isCreateFile = [_fileManager createFileAtPath:_localURL contents:data attributes:nil];
        NSLog(@"Save local json: %d", isCreateFile);
    }
    // 寫入檔案，將 NSData transfer to NSString to write in!
    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [contents writeToFile:_localURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void) saveByFile {
    BOOL isExist = [_fileManager fileExistsAtPath:_localURL];
    if (!isExist) {
        NSLog(@"請先創建檔案 using save(NSData)");
    }

    [[_loaclVersion stringify] writeToFile:_localURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (Boolean) read {
    BOOL isExist = [_fileManager fileExistsAtPath:_localURL];
    NSLog(@"Read file: %d", isExist);
    if(!isExist) {
        return false;
    }

	// read file & parse content to versionFile format!
	NSData *buffer = [_fileManager contentsAtPath: _localURL];
    [_loaclVersion parse:buffer];

	// test for looking file content!
     NSString* tmp = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
     NSLog(@"Read local json: %@", tmp);
    
    return true;
}

- (Bundle*)getBundle:(NSString*) key{
	NSLog(@"getBundle %@ : %@", key, [[_remoteVersion->group objectForKey: key] ToDict]);
    return [_remoteVersion->group objectForKey: key];
}

- (NSMutableArray<Bundle*>*)getBundleArray:(NSString*) bundleName{
	Bundle *gameBundle = [self getBundle:bundleName];
    NSLog(@"getBundleArray length: %lu", gameBundle.dependencies.count);
	if (!gameBundle) {
		return nil;
	}
	NSMutableArray *allBundles = [NSMutableArray arrayWithCapacity:4];
	[allBundles addObject:gameBundle];
	for(int i = 0; i < gameBundle.dependencies.count; i++) {
        NSString *name = gameBundle.dependencies[i];
        NSLog(@"getBundleArray dependencies have: %@", name);
        [allBundles addObject:[self getBundle:name]];
	}

    return allBundles;
}

- (bool) canUpdateSystem {
    if (!_loaclVersion) {
        return true;
    }
   BOOL isequal = [ _remoteVersion->version isEqualToString: _loaclVersion->version];
    return !isequal;
}

- (bool) canUpdateBundle:(NSString*) name{
	if(![_loaclVersion->group objectForKey:name]) {
		NSLog(@"尚未安裝 Bundle %@", name);
		return true;
	}

	Bundle *_myBundle = [_loaclVersion->group objectForKey:name];
	Bundle *_remoteBundle = [self getBundle:name];
	if (![_myBundle.hashId isEqualToString:_remoteBundle.hashId]) {
		NSLog(@"Bundle %@ hashId 不同，待更新", name);
		NSLog(@"_myBundle %@ hashId :", _myBundle.hashId);
		NSLog(@"_remoteBundle %@ hashId :", _remoteBundle.hashId);
		return true;
	}
	NSLog(@"canUpdateBundle Bundle %@ 已更新", name);
    return false;
}

- (void) setBundle:(NSString*) key{
    if ([key isEqualToString:@"app"]) {
		_loaclVersion->version = _remoteVersion->version;
	}

	[_loaclVersion->group setObject:[self getBundle:key] forKey:key];
	[self saveByFile];
}

@end
