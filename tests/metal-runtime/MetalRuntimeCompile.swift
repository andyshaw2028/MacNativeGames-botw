import Foundation
import Metal

func fail(_ message: String) -> Never {
    fputs("FAIL: \(message)\n", stderr)
    exit(1)
}

guard let device = MTLCreateSystemDefaultDevice() else {
    fail("MTLCreateSystemDefaultDevice returned nil")
}
print("Metal device: \(device.name)")

let source = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut test_vertex(uint vid [[vertex_id]]) {
    constexpr float2 positions[3] = {
        float2(0.0, 0.5),
        float2(-0.5, -0.5),
        float2(0.5, -0.5)
    };
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    return out;
}

fragment float4 test_fragment() {
    return float4(1.0, 0.0, 1.0, 1.0);
}
"""

do {
    let library = try device.makeLibrary(source: source, options: nil)
    guard let vertex = library.makeFunction(name: "test_vertex") else {
        fail("compiled library has no test_vertex function")
    }
    guard let fragment = library.makeFunction(name: "test_fragment") else {
        fail("compiled library has no test_fragment function")
    }

    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.label = "Runtime MSL compile smoke test"
    descriptor.vertexFunction = vertex
    descriptor.fragmentFunction = fragment
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

    _ = try device.makeRenderPipelineState(descriptor: descriptor)
    print("PASS: MSL source compiled at runtime and RenderPipelineState was created.")
} catch {
    fail("Metal compile/pipeline failed: \(error)")
}
