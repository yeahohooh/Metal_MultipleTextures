//
//  Render.h
//  Metal_manyTexture
//
//  Created by 李博 on 2021/6/29.
//

#import <Foundation/Foundation.h>

@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface Render : NSObject<MTKViewDelegate>

- (id)initWithMetalKitView: (MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
