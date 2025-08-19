//SystemVerilog
module int_ctrl_group #(
    parameter GROUPS = 2,
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    input wire [GROUPS*WIDTH-1:0] int_in,
    input wire [GROUPS-1:0] group_en,
    output reg [GROUPS-1:0] group_int
);

    // 先行进位思想应用：提前计算每组中断状态
    // Generate (G) 和 Propagate (P) 信号类似CLA的思想
    wire [GROUPS-1:0] group_status;
    
    // 使用生成块优化循环结构
    genvar g;
    generate
        for (g = 0; g < GROUPS; g = g + 1) begin: interrupt_groups
            // 使用位操作代替循环，减少逻辑深度
            wire [WIDTH-1:0] masked_ints;
            assign masked_ints = int_in[(g+1)*WIDTH-1:g*WIDTH] & {WIDTH{group_en[g]}};
            
            // 使用归约操作，类似于先行进位加法器中的并行计算
            assign group_status[g] = |masked_ints;
        end
    endgenerate
    
    // 时序逻辑部分
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            group_int <= {GROUPS{1'b0}};
        end else begin
            group_int <= group_status;
        end
    end
    
endmodule