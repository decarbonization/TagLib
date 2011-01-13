//
//  TLID3MetaData.mm
//  PlayerKit
//
//  Created by Peter MacWhinnie on 9/4/08.
//  Copyright 2008 Roundabout Software. All rights reserved.
//

#import "TLID3MetaData.h"
#import "NSString+TStringAdditions.h"

#import "TagLib.h"
#import "tstring.h"
#import "fileref.h"
#import "mpegfile.h"
#import "id3v2tag.h"
#import "textidentificationframe.h"
#import "unsynchronizedlyricsframe.h"
#import "attachedpictureframe.h"

using namespace TagLib;

@implementation TLID3MetaData

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
	return [NSArray arrayWithObject:@"mp3"];
}

+ (BOOL)canInitWithURL:(NSURL *)url
{
	if(url && [url isFileURL])
	{
		if([[url pathExtension] isEqualToString:@"mp3"])
		{
			MPEG::File file([[url path] fileSystemRepresentation]);
			return (file.isOpen() && file.isValid());
		}
	}
	return NO;
}

- (id)initWithURL:(NSURL *)url error:(NSError **)error
{
	NSAssert([url isFileURL], @"Non-local URL given to TLID3MetaData.");
	
	if(url && (self = [super init]))
	{
		_tagFile = new MPEG::File([[url path] fileSystemRepresentation]);
		if(!_tagFile || !(_tagFile->isOpen() && _tagFile->isValid()))
		{
			if(_tagFile)
			{
				delete _tagFile;
			}
			
			if(error) *error = [NSError errorWithDomain:TLMetaDataErrorDomain 
												   code:NSFileReadUnknownError 
											   userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not open the file %@ with TLID3MetaData. Sorry!", url] 
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
#pragma mark Tag Manipulation

- (void)_removeValueForTag:(const char *)tagName
{
	@synchronized(self)
	{
		ID3v2::Tag *tag = _tagFile->ID3v2Tag();
		if(tag->frameListMap().contains(tagName))
		{
			tag->removeFrames(tagName);
		}
	}
}

- (void)_setString:(NSString *)string forTag:(const char *)tagName
{
	@synchronized(self)
	{
		if(!string)
		{
			[self _removeValueForTag:tagName];
		}
		else
		{
			ID3v2::Tag *tag = _tagFile->ID3v2Tag(true);
			if(tag->frameListMap().contains(tagName))
			{
				tag->frameListMap()[tagName].front()->setText(NSStringToTagLibString(string));
			}
			else
			{
				ID3v2::TextIdentificationFrame *frame = new ID3v2::TextIdentificationFrame(tagName, String::UTF8);
				tag->addFrame(frame);
				frame->setText(NSStringToTagLibString(string));
			}
		}
	}
}

- (NSString *)_stringForTag:(const char *)tagName
{
	@synchronized(self)
	{
		ID3v2::Tag *tag = _tagFile->ID3v2Tag();
		if(tag->frameListMap().contains(tagName))
		{
			ID3v2::FrameList frameList = tag->frameListMap()[tagName];
			ID3v2::Frame *frame = frameList.front();
			return [NSString stringWithTagLibString:frame->toString()];
		}
	}
	return nil;
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
	[self _setString:albumArtist forTag:"TPE2"];
}

- (NSString *)albumArtist
{
	return [self _stringForTag:"TPE2"];
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
		ID3v2::Tag *tag = _tagFile->ID3v2Tag();
		tag->setComment(NSStringToTagLibString(comment));
	}
}

- (NSString *)comment
{
	@synchronized(self)
	{
		return [NSString stringWithTagLibString:_tagFile->tag()->genre()];
	}
	return nil;
}

- (void)setCopyright:(NSString *)copyright
{
	[self _setString:copyright forTag:"TCOP"];
}

- (NSString *)copyright
{
	return [self _stringForTag:"TCOP"];
}

- (void)setEncoder:(NSString *)encoder
{
	[self _setString:encoder forTag:"TENC"];
}

- (NSString *)encoder
{
	return [self _stringForTag:"TENC"];
}

- (void)setArtwork:(NSImage *)artwork
{
	@synchronized(self)
	{
		if(artwork)
		{
			ID3v2::Tag *tag = _tagFile->ID3v2Tag();
			if(tag->frameListMap().contains("APIC"))
			{
				ID3v2::AttachedPictureFrame *frame = dynamic_cast <ID3v2::AttachedPictureFrame *> (tag->frameListMap()["APIC"].front());
				if(frame)
				{
					NSString *mimeType = nil;
					NSData *imageData = TLMetaDataGetDataForImage(artwork, &mimeType);
					frame->setPicture((const char *)[imageData bytes]);
					frame->setMimeType(NSStringToTagLibString(mimeType));
				}
			}
			else
			{
				ID3v2::AttachedPictureFrame *frame = new ID3v2::AttachedPictureFrame();
				tag->addFrame(frame);
				
				NSString *mimeType = nil;
				NSData *imageData = TLMetaDataGetDataForImage(artwork, &mimeType);
				frame->setPicture((const char *)[imageData bytes]);
				frame->setMimeType(NSStringToTagLibString(mimeType));
			}
		}
		else
		{
			[self _removeValueForTag:"APIC"];
		}
	}
}

- (NSImage *)artwork
{
	@synchronized(self)
	{
		ID3v2::Tag *tag = _tagFile->ID3v2Tag();
		if(tag->frameListMap().contains("APIC"))
		{
			ID3v2::AttachedPictureFrame *frame = dynamic_cast <ID3v2::AttachedPictureFrame *> (tag->frameListMap()["APIC"].front());
			if(frame)
			{
				ByteVector frameData = frame->picture();
				NSData *pictureData = [NSData dataWithBytes:frameData.data() length:frameData.size()];
				return [[[NSImage alloc] initWithData:pictureData] autorelease];
			}
		}
	}
	
	return nil;
}

- (void)setLyrics:(NSString *)lyrics
{
	//Because the designer of ID3v2 was apparently high, lyrics do
	//not use the text type, so this method is a special case.
	@synchronized(self)
	{
		if(lyrics)
		{
			ID3v2::Tag *tag = _tagFile->ID3v2Tag();
			if(tag->frameListMap().contains("USLT"))
			{
				tag->frameListMap()["USLT"].front()->setText(NSStringToTagLibString(lyrics));
			}
			else
			{
				ID3v2::UnsynchronizedLyricsFrame *frame = new ID3v2::UnsynchronizedLyricsFrame(String::UTF8);
				tag->addFrame(frame);
				frame->setText(NSStringToTagLibString(lyrics));
			}
		}
		else
		{
			[self _removeValueForTag:"USLT"];
		}
	}
}

- (NSString *)lyrics
{
	return [self _stringForTag:"USLT"];
}

- (void)setComposer:(NSString *)composer
{
	[self _setString:composer forTag:"TCOM"];
}

- (NSString *)composer
{
	return [self _stringForTag:"TCOM"];
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
	NSInteger trackTotal = [self trackTotal];
	if(trackTotal > 0)
	{
		[self _setString:[NSString stringWithFormat:@"%d/%d", trackTotal, trackNumber] forTag:"TRCK"];
	}
	else
	{
		[self _setString:[NSString stringWithFormat:@"%d", trackNumber] forTag:"TRCK"];
	}
}

- (NSInteger)trackNumber
{
	NSString *track = [self _stringForTag:"TRCK"];
	if(track && ([track rangeOfString:@"/"].location != NSNotFound))
	{
		NSArray *components = [track componentsSeparatedByString:@"/"];
		return [[components objectAtIndex:0] integerValue];
	}
	return [track integerValue];
}

- (void)setTrackTotal:(NSInteger)trackTotal
{
	[self _setString:[NSString stringWithFormat:@"%d/%d", [self trackNumber], trackTotal] forTag:"TRCK"];
}

- (NSInteger)trackTotal
{
	NSString *track = [self _stringForTag:"TRCK"];
	if(track && ([track rangeOfString:@"/"].location != NSNotFound))
	{
		NSArray *components = [track componentsSeparatedByString:@"/"];
		return [[components objectAtIndex:1] integerValue];
	}
	return nil;
}

- (void)setDiscNumber:(NSInteger)discNumber
{
	NSInteger discTotal = [self discTotal];
	if(discTotal > 0)
	{
		[self _setString:[NSString stringWithFormat:@"%d/%d", discNumber, discTotal] forTag:"TPOS"];
	}
	else
	{
		[self _setString:[NSString stringWithFormat:@"%d", discNumber] forTag:"TPOS"];
	}
}

- (NSInteger)discNumber
{
	NSString *disc = [self _stringForTag:"TPOS"];
	if(disc && ([disc rangeOfString:@"/"].location != NSNotFound))
	{
		NSArray *components = [disc componentsSeparatedByString:@"/"];
		return [[components objectAtIndex:0] integerValue];
	}
	return [disc integerValue];
}

- (void)setDiscTotal:(NSInteger)discTotal
{
	[self _setString:[NSString stringWithFormat:@"%d/%d", [self discNumber], discTotal] forTag:"TPOS"];
}

- (NSInteger)discTotal
{
	NSString *disc = [self _stringForTag:"TPOS"];
	if(disc && ([disc rangeOfString:@"/"].location != NSNotFound))
	{
		NSArray *components = [disc componentsSeparatedByString:@"/"];
		return [[components objectAtIndex:1] integerValue];
	}
	return 0;
}

#pragma mark -
#pragma mark Attributes

- (double)bitrate
{
	MPEG::Properties *tag = _tagFile->audioProperties();
	return tag->bitrate();
}

- (double)sampleRate
{
	MPEG::Properties *tag = _tagFile->audioProperties();
	return tag->sampleRate();
}

- (NSUInteger)channels
{
	MPEG::Properties *tag = _tagFile->audioProperties();
	return tag->channels();
}

- (NSTimeInterval)duration
{
	MPEG::Properties *tag = _tagFile->audioProperties();
	return tag->length();
}

@end
