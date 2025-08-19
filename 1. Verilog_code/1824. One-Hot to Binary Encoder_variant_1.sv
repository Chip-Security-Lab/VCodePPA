//SystemVerilog
module onehot_to_binary_priority #(parameter OH_WIDTH = 8) (
    input  wire [OH_WIDTH-1:0] onehot_input,
    output wire [$clog2(OH_WIDTH)-1:0] binary_output,
    output wire valid
);
    localparam BIN_WIDTH = $clog2(OH_WIDTH);
    
    assign valid = |onehot_input;
    
    // 使用组合逻辑直接计算输出，避免使用循环
    genvar i;
    generate
        for (i = 0; i < BIN_WIDTH; i = i + 1) begin : gen_binary
            wire [OH_WIDTH-1:0] mask;
            
            genvar k;
            for (k = 0; k < OH_WIDTH; k = k + 1) begin : gen_mask
                assign mask[k] = k[i] ? onehot_input[k] : 1'b0;
            end
            
            assign binary_output[i] = |mask;
        end
    endgenerate
endmodule