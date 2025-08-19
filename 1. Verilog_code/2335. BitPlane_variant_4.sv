//SystemVerilog
//IEEE 1364-2005
module BitPlane #(W=8) (
    input [W-1:0] din,
    output [W/2-1:0] dout
);
    wire [W/2-1:0] upper_half = din[W-1:W/2];
    wire [W/2-1:0] lower_half = din[W/2-1:0];
    
    // 使用优化的借位计算逻辑
    genvar i;
    generate
        // 初始借位为0
        wire [W/2:0] borrows;
        assign borrows[0] = 1'b0;
        
        for (i = 0; i < W/2; i = i + 1) begin : subtract_loop
            // 使用简化的布尔表达式计算差值
            assign dout[i] = upper_half[i] ^ lower_half[i] ^ borrows[i];
            
            // 使用德摩根定律和吸收律简化借位逻辑
            // 原始: (~upper_half[i] & lower_half[i]) | (~upper_half[i] & borrows[i]) | (lower_half[i] & borrows[i])
            // 因子提取: (~upper_half[i] & (lower_half[i] | borrows[i])) | (lower_half[i] & borrows[i])
            // 进一步简化: (~upper_half[i] & (lower_half[i] | borrows[i])) | (lower_half[i] & borrows[i])
            assign borrows[i+1] = (~upper_half[i] & (lower_half[i] | borrows[i])) | 
                                 (lower_half[i] & borrows[i]);
        end
    endgenerate
endmodule