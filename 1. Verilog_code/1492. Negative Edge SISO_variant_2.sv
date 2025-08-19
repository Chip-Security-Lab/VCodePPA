//SystemVerilog
module neg_edge_siso #(parameter DEPTH = 4) (
    input wire clk_n, arst_n, sin,
    output wire sout
);
    // 移位寄存器阵列 - 使用寄存器数组实现
    (* shreg_extract = "yes" *) reg [DEPTH-1:0] sr_array;
    
    // 负边沿触发的时序逻辑
    always @(negedge clk_n or negedge arst_n) begin
        if (!arst_n) begin
            // 异步复位，使用位复制操作优化复位路径
            sr_array <= {DEPTH{1'b0}};
        end else begin
            // 使用位级连接操作优化移位逻辑
            sr_array[DEPTH-1:1] <= sr_array[DEPTH-2:0];
            sr_array[0] <= sin;
        end
    end
    
    // 输出连接到最高位 - 使用连续赋值
    assign sout = sr_array[DEPTH-1];
endmodule