//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;

#if SWIFT_PACKAGE
@import MMMLoadableObjC;
#else
@import MMMLoadable;
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MMMPhotoContentMode) {
	MMMPhotoContentModeAspectFit,
	MMMPhotoContentModeAspectFill
};

/**
 * Protocol for an image that can have different versions depending on the requested resolution.
 * Each version is not necesserely available immediately (follows MMMLoadableImage protocol).
 *
 * (Using "photo" in the name to distinguish this from single fixed resulution images.)
 */
@protocol MMMPhoto <NSObject>

/**
 * A snapshot of the photo suitable for the target size. This way multiple images can be requested from the same photo,
 * like a thumbnail and the large versions, for example.
 *
 * Note that the actual image returned can be larger than the target size, i.e. always treat it as a hint.
 *
 * And as always with loadables, don't assume certain state of the returned image, i.e. it can be completely loaded
 * already, can be syncing or you might have to trigger sync.
 */
- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode;

@end

/**
 * A photo picked from the Photo Library. We are trying to not fetch the actual image till it's needed.
 */
@interface MMMPhotoFromLibrary : NSObject <MMMPhoto>

/** The asset identifier that can be used to find the photo in the Library. */
@property (nonatomic, readonly) NSString *localIdentifier;

- (id)initWithLocalIdentifier:(NSString *)localIdentifier NS_DESIGNATED_INITIALIZER;
- (id)init NS_UNAVAILABLE;

@end

/**
 * A regular UIImage wrapped into the MMMPhoto interface, can be handy for tests.
 */
@interface MMMPhotoFromUIImage : NSObject <MMMPhoto>

- (id)initWithImage:(UIImage *)image NS_DESIGNATED_INITIALIZER;
- (id)init NS_UNAVAILABLE;

@end

/**
 * Another implementation of MMMPhoto handy for tests: the images are downloaded from a web service hosting
 * placeholder images. 
 */
@interface MMMTestPlaceholderPhoto : NSObject <MMMPhoto>

/**
 * The `index` selects the image, i.e. items with the same indices should have the same picture.
 * The `keyword` allows to search for images that fit your app better than "kittens" (default keyword).
 */
- (instancetype)initWithIndex:(NSInteger)index keyword:(NSString *)keyword NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithIndex:(NSInteger)index;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
