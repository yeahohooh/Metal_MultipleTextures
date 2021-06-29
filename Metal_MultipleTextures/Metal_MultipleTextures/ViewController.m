//
//  ViewController.m
//  Metal_MultipleTextures
//
//  Created by 李博 on 2021/6/29.
//

#import "ViewController.h"
#import "Render.h"

@interface ViewController ()
{
    Render *_render;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MTKView *view = [[MTKView alloc] initWithFrame:self.view.frame device:MTLCreateSystemDefaultDevice()];
    [self.view addSubview:view];
    
    if (!view.device) {
        NSLog(@"device error");
        return;
    }
    
    _render = [[Render alloc] initWithMetalKitView:view];
    
    if (!_render) {
        NSLog(@"render error");
        return;
    }
    
    [_render mtkView:view drawableSizeWillChange:view.drawableSize];
    view.delegate = _render;
}


@end
