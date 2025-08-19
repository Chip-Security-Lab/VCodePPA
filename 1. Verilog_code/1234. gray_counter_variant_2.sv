//SystemVerilog
module gray_counter #(parameter WIDTH = 4) (
    input wire clk, reset, enable,
    output reg [WIDTH-1:0] gray_out
);
    reg [WIDTH-1:0] binary;
    reg [WIDTH-1:0] binary_buf;
    
    // 二进制计数器逻辑
    always @(posedge clk) begin
        if (reset) begin
            binary <= 0;
        end else if (enable) begin
            binary <= binary + 1'b1;
        end
    end
    
    // 二进制数据缓冲
    always @(posedge clk) begin
        if (reset) begin
            binary_buf <= 0;
        end else if (enable) begin
            binary_buf <= binary;
        end
    end
    
    // 格雷码转换逻辑
    always @(posedge clk) begin
        if (reset) begin
            gray_out <= 0;
        end else if (enable) begin
            gray_out <= (binary_buf >> 1) ^ binary_buf;
        end
    end
endmodule