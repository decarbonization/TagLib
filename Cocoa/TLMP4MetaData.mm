//
//  TLMP4MetaData.mm
//  PlayerKit
//
//  Created by Peter MacWhinnie on 12/24/08.
//  Copyright 2008 Roundabout Software. All rights reserved.
//

#import "TLMP4MetaData.h"
#import "NSString+TStringAdditions.h"

#import "TagLib.h"
#import "tstring.h"
#import "fileref.h"
#import "mp4file.h"

using namespace TagLib;

@implementation TLMP4MetaData

- (void)finalize
{
	delete _tagFile;
	
	[super finalize];
}

- (void)dealloc
{
	delete _tagFile;
	
	[super dealloc];
}

#pragma mark -

+ (NSArray *)metaDataFileTypes
{
	return [NSArray arrayWithObjects:@"mp4", @"m4a", @"m4p", nil];
}

+ (BOOL)canInitWithURL:(NSURL *)url
{
	if(url && [url isFileURL] && [[self metaDataFileTypes] containsObject:[[url path] pathExtension]])
	{
		MP4::File file([[url path] fileSystemRepresentation]);
		return (file.isOpen() && file.isValid());
	}
	return NO;
}

- (id)initWithURL:(NSURL *)url error:(NSError **)error
{
	NSAssert([url isFileURL], @"Non-local URL given to TLMP4MetaData.");
	
	if(url && (self = [super init]))
	{
		_tagFile = new MP4::File([[url path] fileSystemRepresentation]);
		if(!_tagFile || !(_tagFile->isOpen() && _tagFile->isValid()))
		{
			if(_tagFile)
			{
				delete _tagFile;
			}
			
			if(error) *error = [NSError errorWithDomain:TLMetaDataErrorDomain 
												   code:NSFileReadUnknownError 
											   userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not open the file %@ with TLMP4MetaData. Sorry!", url] 
																					forKey:NSLocalizedDescriptionKey]];
			
			[self release];
			return nil;
		}
		
		return self;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Saving

- (BOOL)canUpdateFile
{
	return !_tagFile->readOnly();
}

- (BOOL)updateFile
{
	if([self canUpdateFile])
	{
		[[NSProcessInfo processInfo] disableSuddenTermination];
		bool result = _tagFile->save();
		[[NSProcessInfo processInfo] enableSuddenTermination];
		return result;
	}
	return NO;
}

#pragma mark -
#pragma mark Metadata

- (void)_removeValueForTag:(const char *)name
{
	NSParameterAssert(name);
	
	@synchronized(self)
	{
		MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
		if(items.contains(name))
		{
			items.erase(name);
		}
	}
}

- (NSString *)_stringForTag:(const char *)name
{
	NSParameterAssert(name);
	
	@synchronized(self)
	{
		MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
		
		String nameAsTagLibString(name);
		if(items.contains(nameAsTagLibString))
		{
			const String &value = items[nameAsTagLibString].toStringList().toString(", ");
			return [NSString stringWithTagLibString:value];
		}
	}
	
	return nil;
}

- (void)_setString:(NSString *)value forTag:(const char *)name
{
	NSParameterAssert(name);
	
	@synchronized(self)
	{
		if(value)
		{
			MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
			items[name] = StringList(NSStringToTagLibString(value));
		}
		else
		{
			[self _removeValueForTag:name];
		}
	}
}

#pragma mark -
#pragma mark Properties

- (void)setTitle:(NSString *)title
{
	@synchronized(self)
	{
		Tag *tag = _tagFile->tag();
		tag->setTitle(NSStringToTagLibString(title));
	}
}

- (NSString *)title
{
	@synchronized(self)
	{
		return [NSString stringWithTagLibString:_tagFile->tag()->title()];
	}
	
	return nil;
}

- (void)setArtist:(NSString *)artist
{
	@synchronized(self)
	{
		Tag *tag = _tagFile->tag();
		tag->setArtist(NSStringToTagLibString(artist));
	}
}

- (NSString *)artist
{
	@synchronized(self)
	{
		return [NSString stringWithTagLibString:_tagFile->tag()->artist()];
	}
	
	return nil;
}

- (void)setAlbum:(NSString *)album
{
	@synchronized(self)
	{
		Tag *tag = _tagFile->tag();
		tag->setAlbum(NSStringToTagLibString(album));
	}
}

- (NSString *)album
{
	@synchronized(self)
	{
		return [NSString stringWithTagLibString:_tagFile->tag()->album()];
	}
	
	return nil;
}

- (void)setAlbumArtist:(NSString *)albumArtist
{
	[self _setString:albumArtist forTag:"aART"];
}

- (NSString *)albumArtist
{
	return [self _stringForTag:"aART"];
}

- (void)setGenre:(NSString *)genre
{
	@synchronized(self)
	{
		Tag *tag = _tagFile->tag();
		tag->setGenre(NSStringToTagLibString(genre));
	}
}

- (NSString *)genre
{
	@synchronized(self)
	{
		return [NSString stringWithTagLibString:_tagFile->tag()->genre()];
	}
	
	return nil;
}

- (void)setComment:(NSString *)comment
{
	@synchronized(self)
	{
		MP4::Tag *tag = _tagFile->tag();
		tag->setComment(NSStringToTagLibString(comment));
	}
}

- (NSString *)comment
{
	@synchronized(self)
	{
		return [NSString stringWithTagLibString:_tagFile->tag()->comment()];
	}
	
	return nil;
}

- (void)setCopyright:(NSString *)copyright
{
	[self _setString:copyright forTag:"cprt"];
}

- (NSString *)copyright
{
	return [self _stringForTag:"cprt"];
}

- (void)setEncoder:(NSString *)encoder
{
	[self _setString:encoder forTag:"\251too"];
}

- (NSString *)encoder
{
	return [self _stringForTag:"\251too"];
}

- (void)setArtwork:(NSImage *)image
{
	@synchronized(self)
	{
		if(image)
		{
			NSData *imageData = TLMetaDataGetDataForImage(image, nil);
			ByteVector imageBytes = ByteVector((const char *)[imageData bytes], [imageData length]);
			ByteVectorList itemList = ByteVectorList();
			itemList.append(imageBytes);
			
			MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
			items["covr"] = MP4::Item(itemList);
		}
		else
		{
			[self _removeValueForTag:"covr"];
		}
	}
}

- (NSImage *)artwork
{
	@synchronized(self)
	{
		MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
		if(items.contains("covr"))
		{
			ByteVector artworkBytes = items["covr"].toByteVectorList()[0];
			NSData *artworkData = [NSData dataWithBytes:artworkBytes.data() length:artworkBytes.size()];
			return [[[NSImage alloc] initWithData:artworkData] autorelease];
		}
	}
	
	return nil;
}

- (void)setLyrics:(NSString *)lyrics
{
	[self _setString:lyrics forTag:"\251lyr"];
}

- (NSString *)lyrics
{
	return [self _stringForTag:"\251lyr"];
}

- (void)setComposer:(NSString *)composer
{
	[self _setString:composer forTag:"\251wrt"];
}

- (NSString *)composer
{
	return [self _stringForTag:"\251wrt"];
}

#pragma mark -

- (void)setYear:(NSInteger)year
{
	@synchronized(self)
	{
		Tag *tag = _tagFile->tag();
		tag->setYear(year);
	}
}

- (NSInteger)year
{
	@synchronized(self)
	{
		return _tagFile->tag()->year();
	}
	
	return 0;
}

- (void)setTrackNumber:(NSInteger)trackNumber
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	items["trkn"] = MP4::Item(trackNumber, [self trackTotal]);
}

- (NSInteger)trackNumber
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	return items["trkn"].toIntPair().first;
}

- (void)setTrackTotal:(NSInteger)trackTotal
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	items["trkn"] = MP4::Item([self trackNumber], trackTotal);
}

- (NSInteger)trackTotal
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	return items["trkn"].toIntPair().second;
}

- (void)setDiscNumber:(NSInteger)discNumber
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	items["disk"] = MP4::Item(discNumber, [self discTotal]);
}

- (NSInteger)discNumber
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	return items["disk"].toIntPair().first;
}

- (void)setDiscTotal:(NSInteger)discTotal
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	items["disk"] = MP4::Item([self discNumber], discTotal);
}

- (NSInteger)discTotal
{
	MP4::ItemListMap &items = _tagFile->tag()->itemListMap();
	return items["disk"].toIntPair().second;
}

#pragma mark -
#pragma mark Attributes

- (double)bitrate
{
	MP4::Properties *tag = _tagFile->audioProperties();
	return tag->bitrate();
}

- (double)sampleRate
{
	MP4::Properties *tag = _tagFile->audioProperties();
	return tag->sampleRate();
}

- (NSUInteger)channels
{
	MP4::Properties *tag = _tagFile->audioProperties();
	return tag->channels();
}

- (NSTimeInterval)duration
{
	MP4::Properties *tag = _tagFile->audioProperties();
	return tag->length();
}

@end
