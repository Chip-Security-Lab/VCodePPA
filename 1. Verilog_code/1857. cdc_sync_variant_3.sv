//SystemVerilog
module cdc_sync #(
    parameter WIDTH = 1
) (
    input  wire               src_clk,    // 源时钟域
    input  wire               dst_clk,    // 目标时钟域
    input  wire               rst,        // 复位信号
    input  wire [WIDTH-1:0]   async_in,   // 异步输入数据
    output reg  [WIDTH-1:0]   sync_out    // 同步输出数据
);
    // 源时钟域寄存器
    reg [WIDTH-1:0] src_data_reg;
    
    // 目标时钟域同步寄存器（两级同步器）
    reg [WIDTH-1:0] dst_sync_reg1;
    reg [WIDTH-1:0] dst_sync_reg2;
    
    // 源时钟域数据寄存 - 第一级流水线
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            src_data_reg <= {WIDTH{1'b0}};
        end else begin
            src_data_reg <= async_in;
        end
    end
    
    // 两级同步器 - 目标时钟域
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            dst_sync_reg1 <= {WIDTH{1'b0}};
            dst_sync_reg2 <= {WIDTH{1'b0}};
            sync_out     <= {WIDTH{1'b0}};
        end else begin
            // 结构化数据流水线
            dst_sync_reg1 <= src_data_reg;    // 第一级同步
            dst_sync_reg2 <= dst_sync_reg1;   // 第二级同步
            sync_out     <= dst_sync_reg2;    // 输出缓冲
        end
    end
    
endmodule