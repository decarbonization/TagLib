//
//  TLMP4MetaData.h
//  PlayerKit
//
//  Created by Peter MacWhinnie on 12/24/08.
//  Copyright 2008 Roundabout Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TagLib/TLMetaData.h>

#ifdef __cplusplus
#	import <TagLib/mp4file.h>
#endif

@interface TLMP4MetaData : TLMetaData
{
#ifdef __cplusplus
	TagLib::MP4::File *_tagFile;
#else
	void *_file;
#endif
}

@end
