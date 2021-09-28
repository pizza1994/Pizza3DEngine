//
//  Renderer.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

import Metal
import MetalKit

public protocol RendererDelegate{
    func update()
}
public class Renderer : NSObject, MTKViewDelegate{
    
    static public let device : MTLDevice? = MTLCreateSystemDefaultDevice()
    let commandQueue : MTLCommandQueue
    var pipelineState: MTLRenderPipelineState? = nil
    var depthStencilState : MTLDepthStencilState? = nil
    let scene : Scene
    private var lastFrameTime : Double = 0
    var deltaTime : Double = 0
    public var cullingMode : MTLCullMode = .none
    #if targetEnvironment(macCatalyst)
    public var sampleCount : Int = 8
    #else
    public var sampleCount : Int = 4
    #endif
    private let gpuLock = DispatchSemaphore(value: 1)
    
    public var delegate : RendererDelegate?
    
    
    public init?(canvas : Canvas, scene : Scene){
        
        canvas.sampleCount = sampleCount
        canvas.depthStencilPixelFormat = .depth32Float
        canvas.scene = scene
        scene.camera.perspectiveSettings.aspectRatio = Float(canvas.bounds.size.width / canvas.bounds.size.height)
        
        canvas.device = Renderer.device!
        
        self.scene = scene
        canvas.createPickingRenderer()

        
        commandQueue = Renderer.device!.makeCommandQueue()!
        
        super.init()
        do {
            pipelineState = try buildRendererPipeline(with: Renderer.device!, metalKitView: canvas)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = Renderer.device!.makeDepthStencilState(descriptor: depthDescriptor)!
        
        
                
    }
    
    public func draw(in view: MTKView) {
        
        let frameTime=CFAbsoluteTimeGetCurrent()
        deltaTime = frameTime-lastFrameTime
        lastFrameTime = frameTime
        guard let canvas = view as? Canvas else{
            print("Not a Canvas")
            return
        }

        gpuLock.wait()
        canvas.update(deltaTime: deltaTime)
        delegate?.update()

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        renderEncoder.label = "StandardEncoder"
        renderEncoder.setRenderPipelineState(pipelineState!)
        renderEncoder.setCullMode(cullingMode)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        scene.draw(encoder: renderEncoder, device: Renderer.device!)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.addScheduledHandler{ _ in self.gpuLock.signal()}
        commandBuffer.commit()
        
        
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    private func buildRendererPipeline(with device : MTLDevice, metalKitView : MTKView) throws -> MTLRenderPipelineState{
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle.module)
        else {fatalError("Unable to create library")}
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .min
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        
        pipelineDescriptor.sampleCount = sampleCount
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
    }
    
    static func makeBuffer(device : MTLDevice, data: UnsafeRawPointer, length : Int, options : MTLResourceOptions = []) -> MTLBuffer{
        let buffer = device.makeBuffer(bytes: data, length: length, options: options)
        return buffer!
    }
    
    
}
