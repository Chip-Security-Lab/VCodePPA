//SystemVerilog
module pl_reg_muxin #(parameter W=8) (
    input clk, sel,
    input [W-1:0] d0, d1,
    output reg [W-1:0] q
);
    wire [W-1:0] result;
    wire [W:0] borrow;
    
    // 先行借位减法器实现
    assign borrow[0] = 1'b0;
    
    generate
        for (genvar i = 0; i < W; i = i + 1) begin : gen_subtractor
            wire p_i = d0[i] ^ 1'b1; // 生成传播信号
            wire g_i = ~d0[i] & d1[i]; // 生成产生信号
            
            assign borrow[i+1] = g_i | (p_i & borrow[i]);
            assign result[i] = d1[i] ^ d0[i] ^ borrow[i];
        end
    endgenerate
    
    always @(posedge clk) begin
        if (sel) begin
            q <= result; // 使用先行借位减法器结果
        end else begin
            q <= d0;
        end
    end
endmodule