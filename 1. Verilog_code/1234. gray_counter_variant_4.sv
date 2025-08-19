//SystemVerilog
module gray_counter #(parameter WIDTH = 4) (
    input wire clk, reset, enable,
    output reg [WIDTH-1:0] gray_out
);
    reg [WIDTH-1:0] binary;
    reg [WIDTH-1:0] next_binary;
    wire [WIDTH-1:0] next_gray;
    
    // 计算下一个二进制值
    always @(*) begin
        next_binary = enable ? (binary + 1'b1) : binary;
    end
    
    // 二进制到格雷码的转换优化
    assign next_gray = (next_binary >> 1) ^ next_binary;
    
    // 时序逻辑
    always @(posedge clk) begin
        if (reset) begin
            binary <= {WIDTH{1'b0}};
            gray_out <= {WIDTH{1'b0}};
        end else begin
            binary <= next_binary;
            gray_out <= next_gray;
        end
    end
endmodule