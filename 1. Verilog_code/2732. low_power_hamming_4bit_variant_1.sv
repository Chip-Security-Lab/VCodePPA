//SystemVerilog
module low_power_hamming_4bit(
    input clk, sleep_mode,
    input [3:0] data,
    output reg [6:0] encoded
);
    // 使用专用的时钟门控单元代替简单的AND门
    // 这可以减少潜在的毛刺并提高时钟树质量
    reg clk_en;
    wire gated_clk;
    
    always @(negedge clk or posedge sleep_mode) begin
        if (sleep_mode)
            clk_en <= 1'b0;
        else
            clk_en <= ~sleep_mode;
    end
    
    // 时钟门控单元，避免使用简单的AND门
    assign gated_clk = clk & clk_en;
    
    // 预计算奇偶校验位，避免在always块中多次计算相同的XOR操作
    wire p0, p1, p2;
    assign p0 = data[0] ^ data[1] ^ data[3];
    assign p1 = data[0] ^ data[2] ^ data[3];
    assign p2 = data[1] ^ data[2] ^ data[3];
    
    // 使用单一的状态更新，减少寄存器写入操作
    always @(posedge gated_clk) begin
        if (sleep_mode)
            encoded <= 7'b0;
        else begin
            // 将数据和校验位打包成一次性赋值，提高综合效率
            encoded <= {data[3], data[2], data[1], p2, data[0], p1, p0};
        end
    end
endmodule