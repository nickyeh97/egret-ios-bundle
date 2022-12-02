#import "BundleManager.h"
#import "zipArchive/ZipArchive.h"
#import "Bundle.h"


typedef void(^Block)();
// Block cheat sheet 
// https://gist.github.com/youngshook/9939865

@implementation BundleManager {
	unsigned long   _loadedCount;
	unsigned long   _targetCount;
	NSString*		_localPath;
    Block           _finishCallback;
	VersionManager*	_vm;
}

-(id) initWithPath:(NSString*) localPath versionMgr:(VersionManager*) versionMgr
{
	if( self=[super init] )
	{
		_loadedCount = 0;
		_targetCount = 0;
        _localPath = localPath;
        _vm = versionMgr;
	}
	return self;
}

- (void)upgrade:(NSString*) name bundles:(NSArray*) bundles success:(void(^)()) cb {
	if(_loadedCount != 0) {
        NSLog(@"Still load others resouce , can not upgrade another games!");
		return;
	}

	_loadedCount = 0;
	_targetCount = bundles.count;
	if(cb) {
		_finishCallback = cb;
	}

    NSLog(@" Bundle name: %@ 等待更新, Bundles : %@ , cb : %@", name, bundles, cb);
	unsigned long _passCount = 0;
	for(int i = 0; i < bundles.count; i++) {
        Bundle *res = bundles[i];
		if ([_vm canUpdateBundle:res.name]) {
			[self loadGameRes:res.name bundle:res];
		}
		else {
			_loadedCount++;
			_passCount++;
			if(_loadedCount == _targetCount) {
				NSLog(@"下載壓縮完畢，有%lu包無需更新， _targetCount: %lu", _passCount, _targetCount);
				_loadedCount = 0;
				_targetCount = 0;
				if(cb) {
					cb();
				}
			}
		}
	}
}

- (void)loadGameRes:(NSString*) name bundle:(Bundle*) bundle {
	NSString *fileUrl = bundle.url;
    NSURLSession* session = [NSURLSession sharedSession];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fileUrl]];
    request.timeoutInterval = 10.0;
    request.HTTPMethod = @"GET";
    NSLog(@"下載 Bundle name: %@ , fileUrl : %@", name, fileUrl);
    
	NSString* bundleName = name;
    NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request
				completionHandler:^(NSURL* location, NSURLResponse* response, NSError* error) {
					if (error != nil) {
						NSLog(@"ERROR: %@", [error localizedDescription]);
						return;
					}
					// 建立父資料夾
					NSError* err;
                    NSString* dir = self->_localPath;
					NSLog(@"設定的壓縮檔檔案路徑: dir: %@", dir);
					[[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&err];
					if (err != nil) {
						NSLog(@"ERROR: create parent file failed: %@", dir);
						return;
					}
					
					NSString* zipFilePath = [dir stringByAppendingString:@"temp.zip"];
					NSLog(@"下載的壓縮檔檔案路徑: %@", location.path);
					NSLog(@"想要搬移到的壓縮檔檔案路徑: %@", zipFilePath);
					[[NSFileManager defaultManager] moveItemAtPath:location.path toPath:zipFilePath error:&err];
					if (err != nil) {
						NSLog(@"ERROR: create file failed: %@", zipFilePath);
						return;
					}
					
					ZipArchive* zip = [[ZipArchive alloc] init];
					if (![zip UnzipOpenFile:zipFilePath]) {
						NSLog(@"ERROR: failed to open zip file");
						return;
					}

					NSString* targetDir = [dir stringByAppendingString:bundle.path];
					[[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&err];
					NSLog(@"遊戲資源檔案路徑: %@", targetDir);
					bool result = [zip UnzipFileTo:targetDir overWrite:YES];
					if (!result) {
						NSLog(@"ERROR: failed to unzip files");
						return;
					}
                    self->_loadedCount++;
					[zip UnzipCloseFile];
					[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];

					[self->_vm setBundle:bundleName];
					if(self->_loadedCount == self->_targetCount) {
						//Call finish cb
						NSLog(@"下載壓縮完畢， _loadedCount: %lu ， _targetCount: %lu", self->_loadedCount, self->_targetCount);
                        self->_loadedCount = 0;
                        self->_targetCount = 0;
						if (self->_finishCallback) {
                            self->_finishCallback();
						}
					}
				}];
    [task resume];
}

+ (NSString*)getFileDirByUrl:(NSString*)urlString {
    long lastSlash = [urlString rangeOfString:@"/" options:NSBackwardsSearch].location;
    NSString* server = [urlString substringToIndex:lastSlash + 1];
    server = [server stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    server = [server stringByReplacingOccurrencesOfString:@":" withString:@"#0A"];
    return server;
}

@end
