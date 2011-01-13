//
//  TLID3MetaData.h
//  PlayerKit
//
//  Created by Peter MacWhinnie on 9/4/08.
//  Copyright 2008 Roundabout Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TagLib/TLMetaData.h>

/*
	Truly this is unspeakably evil:
 */
#ifdef __cplusplus
#	import <TagLib/mpegfile.h>
#endif

@interface TLID3MetaData : TLMetaData
{
#ifdef __cplusplus
	TagLib::MPEG::File *_tagFile;
#else
	void *_file;
#endif
}

@end
