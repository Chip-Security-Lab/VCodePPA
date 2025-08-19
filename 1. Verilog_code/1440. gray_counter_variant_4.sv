//SystemVerilog
module gray_counter #(parameter W=4) (
    input  wire        clk,
    input  wire        rstn,
    output reg  [W-1:0] gray
);

    reg [W-1:0] bin;
    wire [W-1:0] next_bin;
    wire [W-1:0] next_gray;
    
    // 使用连续赋值实现下一个二进制值的计算
    assign next_bin = bin + 1'b1;
    
    // 使用高效的格雷码转换公式：G = B ^ (B >> 1)
    assign next_gray = next_bin ^ (next_bin >> 1);
    
    always @(posedge clk) begin
        if (!rstn) begin
            bin  <= {W{1'b0}};
            gray <= {W{1'b0}};
        end
        else begin
            bin  <= next_bin;
            gray <= next_gray;
        end
    end

endmodule