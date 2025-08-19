//SystemVerilog
module error_detect_demux (
    input wire data,                     // Input data
    input wire [2:0] address,            // Address selection
    output reg [4:0] outputs,            // Output lines
    output reg error_flag                // Error indication
);
    // 声明用于地址解码的信号
    reg [7:0] address_decoded;
    
    // 地址解码独立always块
    always @(*) begin
        address_decoded = 8'b00000001 << address;
    end
    
    // 输出信号设置独立always块
    always @(*) begin
        outputs = 5'b00000;
        
        if (address_decoded[0])
            outputs[0] = data;
        if (address_decoded[1])
            outputs[1] = data;
        if (address_decoded[2])
            outputs[2] = data;
        if (address_decoded[3])
            outputs[3] = data;
        if (address_decoded[4])
            outputs[4] = data;
    end
    
    // 错误标志独立always块
    always @(*) begin
        error_flag = 1'b0;
        
        if (address_decoded[5] || address_decoded[6] || address_decoded[7])
            error_flag = data;
    end
endmodule