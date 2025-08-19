//SystemVerilog
module gray_counter #(parameter W=4) (
    input wire clk, rstn,
    output reg [W-1:0] gray
);
    reg [W-1:0] bin;
    wire [W-1:0] next_bin;
    wire [W-1:0] next_gray;
    wire [W-1:0] shifted_next_bin;
    
    // 计算下一个二进制值
    assign next_bin = bin + 1'b1;
    
    // 桶形移位器实现右移一位操作
    // 对于W位的数据，右移1位只需要直接连接
    assign shifted_next_bin[W-2:0] = next_bin[W-1:1];
    assign shifted_next_bin[W-1] = 1'b0;
    
    // 灰码计算
    assign next_gray = next_bin ^ shifted_next_bin;
    
    always @(posedge clk) begin
        if (!rstn) begin
            bin <= {W{1'b0}};
            gray <= {W{1'b0}};
        end else begin
            bin <= next_bin;
            gray <= next_gray;
        end
    end
endmodule