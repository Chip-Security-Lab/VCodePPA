//SystemVerilog
module differential_encoder (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    input  wire       data_input,
    output wire       diff_encoded
);
    // 优化后的寄存器结构
    reg prev_encoded;
    reg curr_encoded;
    
    // 将输出直接连接到内部寄存器，移除了输出寄存器
    assign diff_encoded = curr_encoded;
    
    // 合并时序逻辑：同时更新两个寄存器
    always @(posedge clock) begin
        if (reset) begin
            curr_encoded <= 1'b0;
            prev_encoded <= 1'b0;
        end else if (enable) begin
            // 将组合逻辑计算直接嵌入到时序块中
            curr_encoded <= data_input ^ prev_encoded;
            prev_encoded <= curr_encoded;
        end
    end
endmodule