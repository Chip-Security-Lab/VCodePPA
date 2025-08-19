//SystemVerilog
module differential_encoder (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    input  wire       data_input,
    output wire       diff_encoded
);
    // 寄存器声明
    reg current_encoded;  // 当前编码值
    reg prev_encoded;     // 上一个编码值
    
    // 组合逻辑计算差分编码
    assign diff_encoded = current_encoded;
    
    // 计算当前编码值
    always @(posedge clock) begin
        if (reset) begin
            current_encoded <= 1'b0;
        end else if (enable) begin
            current_encoded <= data_input ^ prev_encoded;
        end
    end
    
    // 更新前一个编码值
    always @(posedge clock) begin
        if (reset) begin
            prev_encoded <= 1'b0;
        end else if (enable) begin
            prev_encoded <= current_encoded;
        end
    end
endmodule