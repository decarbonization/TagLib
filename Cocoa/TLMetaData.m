//
//  PKMetaData.m
//  TagLib
//
//  Created by Peter MacWhinnie on 5/5/08.
//  Copyright 2008 Roundabout Software, LLC. All rights reserved.
//

#import "TLMetaData.h"
#import <objc/runtime.h>

#pragma mark Artwork

NSString *const TLMetaDataErrorDomain = @"TLMetaDataErrorDomain";

NSBitmapImageFileType kTLMetaDataArtworkFormat = NSPNGFileType;

NSString *__PKMetaDataGetMimeTypeForImageType(NSBitmapImageFileType fileType)
{
	switch (fileType)
	{
		case NSTIFFFileType: return @"image/tiff";
		case NSBMPFileType: return @"image/bmp";
		case NSGIFFileType: return @"image/gif";
		case NSJPEGFileType: return @"image/jpeg";
		case NSPNGFileType: return @"image/png";
		case NSJPEG2000FileType: return @"image/jp2";
		default: break;
	}
	return nil;
}

NSData *TLMetaDataGetDataForImage(NSImage *image, NSString **mimeType)
{
	NSCParameterAssert(image);
	
	//We attempt to get an existing image representation from the image.
	NSBitmapImageRep *imageRep = nil;
	for (id representation in [image representations])
	{
		if([representation isKindOfClass:[NSBitmapImageRep class]])
		{
			imageRep = representation;
			break;
		}
	}
	
	//If there is no existing image representation, we just make a new
	//representation in the usual, incredibly inefficient manner.
	if(!imageRep)
		imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
	
	if(mimeType) *mimeType = __PKMetaDataGetMimeTypeForImageType(kTLMetaDataArtworkFormat);
	return [imageRep representationUsingType:kTLMetaDataArtworkFormat properties:nil];
}

#pragma mark -
#pragma mark Class Cluster

static NSMutableSet *PKMetaDataGetClasses()
{
	static NSMutableSet *classes = nil;
	if(!classes)
	{
		classes = [[NSMutableSet alloc] initWithObjects:
				   objc_lookUpClass("TLID3MetaData"),
				   objc_lookUpClass("TLMP4MetaData"),
				   nil];
	}
	
	return classes;
}

@implementation TLMetaData

#pragma mark Class Cluster Methods

+ (void)registerMetadataClass
{
	[PKMetaDataGetClasses() addObject:self];
}

+ (NSSet *)registeredClasses
{
	return PKMetaDataGetClasses();
}

+ (Class)metaDataClassForURL:(NSURL *)url
{
	if(url)
	{
		for (Class class in PKMetaDataGetClasses())
		{
			if([class canInitWithURL:url])
				return class;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Creation

+ (NSArray *)metaDataFileTypes
{
	if([self class] != [TLMetaData class])
		return nil;
	
	NSMutableArray *fileTypes = [NSMutableArray array];
	for (Class class in PKMetaDataGetClasses())
		[fileTypes addObjectsFromArray:[class metaDataFileTypes]];
	
	return fileTypes;
}

+ (BOOL)canInitWithURL:(NSURL *)url
{
	NSParameterAssert(url);
	
	//This guards against accidental infinite recursion.
	if([self class] != [TLMetaData class])
		return NO;
	
	return ([self metaDataClassForURL:url] != nil);
}

- (id)initWithURL:(NSURL *)url openReadOnly:(BOOL)openReadOnly error:(NSError **)error
{
	NSParameterAssert(url);
	
	//This guards against accidental infinite recursion.
	if([self class] != [TLMetaData class])
		return [super init];
	
	Class metaDataClass = [[self class] metaDataClassForURL:url];
	
	if(!metaDataClass)
		return nil;
	
	TLMetaData *newSelf = [[metaDataClass alloc] initWithURL:url openReadOnly:openReadOnly error:error];
	if(newSelf)
	{
		[self release];
		self = newSelf;
		
		return self;
	}
	
	return nil;
}

#pragma mark -

- (void)synchronizeValuesWithMetaData:(TLMetaData *)sourceMetadata
{
	NSParameterAssert(sourceMetadata);
	
	self.title = sourceMetadata.title;
	self.artist = sourceMetadata.artist;
	self.album = sourceMetadata.album;
	self.albumArtist = sourceMetadata.albumArtist;
	self.genre = sourceMetadata.genre;
	self.comment = sourceMetadata.comment;
	self.copyright = sourceMetadata.copyright;
	self.encoder = sourceMetadata.encoder;
	self.artwork = sourceMetadata.artwork;
	self.lyrics = sourceMetadata.lyrics;
	self.composer = sourceMetadata.composer;
	self.year = sourceMetadata.year;
	self.trackNumber = sourceMetadata.trackNumber;
	self.trackTotal = sourceMetadata.trackTotal;
	self.discNumber = sourceMetadata.discNumber;
	self.discTotal = sourceMetadata.discTotal;
}

- (BOOL)canUpdateFile
{
	return NO;
}

- (BOOL)updateFile
{
	return NO;
}

#pragma mark -
#pragma mark Meta data

- (void)setTitle:(NSString *)title
{
}

- (NSString *)title
{
	return nil;
}

- (void)setArtist:(NSString *)artist
{
}

- (NSString *)artist
{
	return nil;
}

- (void)setAlbum:(NSString *)album
{
}

- (NSString *)album
{
	return nil;
}

- (void)setAlbumArtist:(NSString *)albumArtist
{
}

- (NSString *)albumArtist
{
	return nil;
}

- (void)setGenre:(NSString *)genre
{
}

- (NSString *)genre
{
	return nil;
}

- (void)setComment:(NSString *)comment
{
}

- (NSString *)comment
{
	return nil;
}

- (void)setCopyright:(NSString *)copyright
{
}

- (NSString *)copyright
{
	return nil;
}

- (void)setEncoder:(NSString *)encoder
{
}

- (NSString *)encoder
{
	return nil;
}

- (void)setArtwork:(NSImage *)artwork
{
}

- (NSImage *)artwork
{
	return nil;
}

- (void)setLyrics:(NSString *)lyrics
{
}

- (NSString *)lyrics
{
	return nil;
}

- (void)setComposer:(NSString *)composer
{
}

- (NSString *)composer
{
	return nil;
}

- (void)setYear:(NSInteger)year
{
}

- (NSInteger)year
{
	return 0;
}

- (void)setTrackNumber:(NSInteger)trackNumber
{
}

- (NSInteger)trackNumber
{
	return 0;
}

- (void)setTrackTotal:(NSInteger)trackTotal
{
}

- (NSInteger)trackTotal
{
	return 0;
}

- (void)setDiscNumber:(NSInteger)discNumber
{
}

- (NSInteger)discNumber
{
	return 0;
}

- (void)setDiscTotal:(NSInteger)discTotal
{
}

- (NSInteger)discTotal
{
	return 0;
}

#pragma mark -

- (NSArray *)chapters
{
	return [NSArray array];
}

#pragma mark -

- (BOOL)isDRMProtected
{
	return NO;
}

- (BOOL)isDRMAuthorized
{
	return NO;
}

#pragma mark -

- (double)bitrate
{
	return 0.0;
}

- (double)sampleRate
{
	return 0.0;
}

- (NSUInteger)channels
{
	return 0;
}

- (NSTimeInterval)duration
{
	return 0.0;
}

@end
