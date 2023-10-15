//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMPhoto.h"

#import "MMMPhotoLibraryLoadableImage.h"
@import Photos;
@import MMMCommonCore;

//
//
//
@implementation MMMPhotoFromLibrary

- (id)initWithLocalIdentifier:(NSString *)localIdentifier {
	if (self = [super init]) {
		_localIdentifier = localIdentifier;
	}
	return self;
}

- (PHImageContentMode)PHImageContentModeFromContentMode:(MMMPhotoContentMode)contentMode {
	switch (contentMode) {
		case MMMPhotoContentModeAspectFit:
			return PHImageContentModeAspectFit;
		case MMMPhotoContentModeAspectFill:
			return PHImageContentModeAspectFill;
	}
}

- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode {
	return [[MMMPhotoLibraryLoadableImage alloc]
		initWithLocalIdentifier:_localIdentifier
		targetSize:targetSize
		contentMode:[self PHImageContentModeFromContentMode:contentMode]
	];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: asset '%@'>", self.class, _localIdentifier];
}

@end

//
//
//
@implementation MMMPhotoFromUIImage {
	MMMImmediateLoadableImage *_loadable;
	UIImage *_image;
}

- (id)initWithImage:(UIImage *)image {

	if (self = [super init]) {

		// TODO: downscale it to the size that makes sense asap, then get rid of the original
		_image = image;
	}

	return self;
}

- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode {

	// TODO: For now we don't trim it for different target sizes, but maybe we should downscale when a thumbnail is requested.
	if (!_loadable) {
		_loadable = [[MMMImmediateLoadableImage alloc] initWithImage:_image];
	}

	return _loadable;
}

@end

//
//
//
@implementation MMMTestPlaceholderPhoto {
	NSInteger _index;
	NSString *_keyword;
}

- (instancetype)initWithIndex:(NSInteger)index {
	return [self initWithIndex:index keyword:@"kitten"]; // This was the default on the service.
}

- (instancetype)initWithIndex:(NSInteger)index keyword:(NSString *)keyword {

    if (self = [super init]) {
    	_index = index;
    	_keyword = keyword;
    }

    return self;
}

- (id<MMMLoadableImage>)imageForTargetSize:(CGSize)targetSize contentMode:(MMMPhotoContentMode)contentMode {
	NSString *url = [NSString
		stringWithFormat:@"https://loremflickr.com/%li/%li/%@?lock=%li",
		(long)targetSize.width, (long)targetSize.height,
		MMMQueryStringFromParametersEscape(_keyword),
		(long)_index
	];
	return [[MMMPublicLoadableImage alloc] initWithURL:[NSURL URLWithString:url]];
}

@end
