//
//  TLMetaData.h
//  TagLib
//
//  Created by Peter MacWhinnie on 5/5/08.
//  Copyright 2008 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

__BEGIN_DECLS

extern NSString *const TLMetaDataErrorDomain;

/*!
 @constant	kTLMetaDataArtworkFormat
 @abstract	The NSBitmapImageFileType to use when getting data for an image.
			By default this value is NSPNGFileType.
 */
extern NSBitmapImageFileType kTLMetaDataArtworkFormat; 

/*!
 @function	TLMetaDataGetDataForImage
 @abstract	Get the data for an image in the preferred format.
 */
extern NSData *TLMetaDataGetDataForImage(NSImage *image, NSString **mimeType);

#pragma mark -

/*!
 @class
 @abstract		This class is used for reading and writing metadata through TagLib with Cocoa.
 @discussion	TLMetaData is a class cluster that delegates the actual job of reading and writing
				metadata in files to its concrete subclasses.
				
				Subclasses are expected to implement metaDataFileTypes, canInitWithURL:,
				and initWithContentsOfURL:error:. Default implementations that do nothing are provided for
				all methods unless noted otherwise.
 */
@interface TLMetaData : NSObject
{
}
/*!
 @method
 @abstract	This method should be invoked in the load method of any TLMetaData subclass
			that wants to participate in the metadata class cluster.
 */
+ (void)registerMetadataClass;

/*!
 @method
 @abstract	Get the registered metadata classes in the TLMetaData class cluster.
 */
+ (NSSet *)registeredClasses;

/*!
 @method
 @abstract		The	file types that TLMetaData can open.
 @discussion	This method should be overriden by subclasses to provide the file types they understand.
				TLMetaData will call this method on each class in the TLMetaData cluster and collect the
				results to produce an overview of what TLMetaData can handle.
 */
+ (NSArray *)metaDataFileTypes;

/*!
 @method
 @abstract		Returns whether or not TLMetaData can edit a file at a specified URL.
 @discussion	This method should be overriden by subclasses. TLMetaData will call this method
				on classes in the cluster until it finds one that returns YES.
				
				(Note, TLMetaData's built in classes _do not_ understand remote URLs.)
 */
+ (BOOL)canInitWithURL:(NSURL *)url;

/*!
 @method
 @abstract		Initialize a TLMetaData object with a URL. This is the designated initializer of TLMetaData.
 @param			url		The URL of the file to initialize TLMetaData to edit. May not be nil.
 @param			error	On return, any error that might have occurred during execution of this method.
 @result	A new instance of TLMetaData if the URL can be read from/written to; nil otherwise.
 @discussion	This method should be overriden by subclasses. TLMetaData will call this method on a
				subclass if it finds a class that is capable of handling the URL passed to it.
				
				(Note, TLMetaData's built in classes _do not_ understand remote URLs.)
 */
- (id)initWithURL:(NSURL *)url error:(NSError **)error;

/*!
 @method
 @abstract	Indicates whether the receiver can be updated with changes made to the object.
 */
- (BOOL)canUpdateFile;

/*!
 @method	  
 @abstract		Updates the file of a TLMetaData object.
 @result	YES if the update succeeds; NO otherwise.
 */
- (BOOL)updateFile;

/*!
 @method
 @abstract	Take the values from another TLMetaData object and apply them to the receiver.
 */
- (void)synchronizeValuesWithMetaData:(TLMetaData *)other;

/*!
 @property
 @abstract	The title of the receiver
 */
@property (copy) NSString *title;

/*!
 @property
 @abstract	The artist of the receiver
 */
@property (copy) NSString *artist;

/*!
 @property
 @abstract	The album of the receiver
 */
@property (copy) NSString *album;

/*!
 @property
 @abstract	The album artist of the receiver
 */
@property (copy) NSString *albumArtist;

/*!
 @property
 @abstract	The genre of the receiver
 */
@property (copy) NSString *genre;

/*!
 @property
 @abstract	The comment of the receiver
 */
@property (copy) NSString *comment;

/*!
 @property
 @abstract	The copyright of the receiver
 */
@property (copy) NSString *copyright;

/*!
 @property
 @abstract	The encoder of the receiver
 */
@property (copy) NSString *encoder;

/*!
 @property
 @abstract	The artwork image of the receiver
 */
@property (copy) NSImage *artwork;

/*!
 @property
 @abstract	The lyrics of the receiver
 */
@property (copy) NSString *lyrics;

/*!
 @property
 @abstract	The composer of the receiver
 */
@property (copy) NSString *composer;

/*!
 @property
 @abstract	The year of the receiver
 */
@property NSInteger year;

/*!
 @property
 @abstract	The track number of the receiver
 */
@property NSInteger trackNumber;

/*!
 @property
 @abstract	The track total of the receiver
 */
@property NSInteger trackTotal;

/*!
 @property
 @abstract	The disc number of the receiver
 */
@property NSInteger discNumber;

/*!
 @property
 @abstract	The disc total of the receiver
 */
@property NSInteger discTotal;

/*!
 @property
 @abstract	The bitrate of the receiver
 */
@property (readonly) double bitrate;

/*!
 @property
 @abstract	The sampleRate of the receiver
 */
@property (readonly) double sampleRate;

/*!
 @property
 @abstract	The number of channels of the receiver
 */
@property (readonly) NSUInteger channels;

/*!
 @property
 @abstract	The duration in seconds of the receiver
 */
@property (readonly) NSTimeInterval duration;

/*!
 @property
 @abstract	The chapters (if any) in the metadata.
 */
@property (readonly) NSArray *chapters;

/*!
 @property
 @abstract	Whether or not the file being edited by TLMetaData is protected.
 */
@property (readonly) BOOL isDRMProtected;

/*!
 @property
 @abstract	Whether or not the protected file being edited by TLMetaData is authorized for playback.
 */
@property (readonly) BOOL isDRMAuthorized;
@end

__END_DECLS
