//SystemVerilog
// SystemVerilog
module differential_encoder (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    input  wire       data_input,
    output wire       diff_encoded
);
    // 使用寄存器保存当前编码状态
    reg encoded_state;
    
    // 将输出从reg改为wire，通过组合逻辑直接计算
    assign diff_encoded = encoded_state;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            encoded_state <= 1'b0;
        end else if (enable) begin
            encoded_state <= data_input ^ encoded_state;
        end
    end
endmodule