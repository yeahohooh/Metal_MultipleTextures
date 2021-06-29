//
//  Render.m
//  Metal_manyTexture
//
//  Created by 李博 on 2021/6/29.
//

#import "Render.h"
#import "ShaderTypes.h"

@implementation Render
{
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLCommandQueue> _commandQueue;
    id<MTLTexture> _texture;
    id<MTLBuffer> _vertexBuffer;
    vector_uint2 _viewportSize; // 视图大小
    NSInteger _numVertices; // 顶点个数
}

- (id)initWithMetalKitView:(MTKView *)mtkView {
    if (self = [super init]) {
        _device = mtkView.device;
        [self loadMetalWithView:mtkView];
        [self loadTexture];
    }
    return self;
}

- (void)loadMetalWithView:(nonnull MTKView *)view {
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.label = @"texturePipeline";
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"pipelineState error--%@",error);
    }
    
    _commandQueue = [_device newCommandQueue];
}

- (void)loadTexture {
    NSError *error;
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    NSDictionary *textureLoaderOptions = @{MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
                                           MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)};
    _texture = [textureLoader newTextureWithName:@"nazimei" scaleFactor:1.0 bundle:nil options:textureLoaderOptions error:&error];
    if (!_texture || error) {
        NSLog(@"texture error -- %@", error);
    }
    
    NSData *vertexData = [Render generateVertexData];
    _vertexBuffer = [_device newBufferWithLength:vertexData.length options:MTLResourceStorageModeShared];
    memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
    
    _numVertices = vertexData.length / sizeof(Vertex);
}

+ (nonnull NSData*)generateVertexData{
    const Vertex quadVertices[] =
    {
        // 位置, 纹理坐标
        { { -20,   20 },    { 0.0, 0.0 } },
        { {  20,   20 },    { 1.0, 0.0 } },
        { { -20,  -20 },    { 0.0, 1.0 } },
        
        { {  20,  -20 },    { 1.0, 1.0 } },
        { { -20,  -20 },    { 0.0, 1.0 } },
        { {  20,   20 },    { 1.0, 0.0 } }
    };
    //行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(Vertex);
    //四边形间距
    const float QUAD_SPACING = 50.0;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSInteger dataStr = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataStr];
    //当前四边形
    Vertex *currentQuad = vertexData.mutableBytes;
    
    //行
    for (NSUInteger row = 0; row < NUM_ROWS; row++) {
        //列
        for (NSUInteger column = 0; column < NUM_COLUMNS; column++) {
            //A.左上角的位置
            vector_float2 upperLeftPosition;
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
            //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
            //D.遍历currentQuad中的数据 总共6个顶点 每个顶点的position依次加
            // 其实就相当于每个点对应左上角第一个点的偏移量 加上去之后就是当前位置了
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++) {
                //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            //E.更新索引
            currentQuad += 6;
        }
    }
    return vertexData;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"myCommand";
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        commandEncoder.label = @"myRenderEncoder";
        
        [commandEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
        [commandEncoder setRenderPipelineState:_pipelineState];
        [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:1];
        [commandEncoder setFragmentTexture:_texture atIndex:0];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}

@end
