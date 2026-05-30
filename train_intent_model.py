import numpy as np
import onnx
import onnxruntime as ort
from onnx import helper, TensorProto

def create_intent_model():
    X = helper.make_tensor_value_info('input', TensorProto.FLOAT, [None, 160])
    Y = helper.make_tensor_value_info('output', TensorProto.FLOAT, [None, 7])
    
    W1 = helper.make_tensor('W1', TensorProto.FLOAT, [160, 64], 
                           np.random.randn(160, 64).astype(np.float32) * 0.01)
    b1 = helper.make_tensor('b1', TensorProto.FLOAT, [64], 
                           np.zeros(64, dtype=np.float32))
    
    W2 = helper.make_tensor('W2', TensorProto.FLOAT, [64, 7], 
                           np.random.randn(64, 7).astype(np.float32) * 0.01)
    b2 = helper.make_tensor('b2', TensorProto.FLOAT, [7], 
                           np.zeros(7, dtype=np.float32))
    
    node1 = helper.make_node('Gemm', ['input', 'W1', 'b1'], ['hidden'], transB=0)
    node2 = helper.make_node('Relu', ['hidden'], ['hidden_relu'])
    node3 = helper.make_node('Gemm', ['hidden_relu', 'W2', 'b2'], ['logits'], transB=0)
    node4 = helper.make_node('Softmax', ['logits'], ['output'], axis=1)
    
    graph = helper.make_graph(
        [node1, node2, node3, node4],
        'intent_classifier',
        [X],
        [Y],
        [W1, b1, W2, b2]
    )
    
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 13)])
    return model

def save_model(model, path):
    onnx.save(model, path)
    print(f"Model saved to {path}")

def test_model(path):
    session = ort.InferenceSession(path)
    test_input = np.random.randn(1, 160).astype(np.float32)
    output = session.run(None, {'input': test_input})
    print(f"Test output shape: {output[0].shape}")
    print(f"Test output: {output[0]}")

if __name__ == '__main__':
    model = create_intent_model()
    save_model(model, 'assets/models/intent_model.onnx')
    test_model('assets/models/intent_model.onnx')