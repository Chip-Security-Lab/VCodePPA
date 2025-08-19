//SystemVerilog
//IEEE 1364-2005
module Demux_SyncEn #(parameter DW=8, AW=3) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output reg [(1<<AW)-1:0][DW-1:0] data_out,
    // 流水线控制信号
    input ready_in,
    output reg ready_out,
    input valid_in,
    output reg valid_out
);

    // 流水线寄存器 - 第一级
    reg [DW-1:0] data_stage1;
    reg [AW-1:0] addr_stage1;
    reg valid_stage1;
    reg en_stage1;
    
    // 流水线寄存器 - 第二级
    reg [DW-1:0] data_stage2;
    reg [AW-1:0] addr_stage2;
    reg valid_stage2;
    reg en_stage2;
    
    // 合并所有posedge clk or negedge rst_n触发的always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 第一级流水线复位
            data_stage1 <= 0;
            addr_stage1 <= 0;
            valid_stage1 <= 0;
            en_stage1 <= 0;
            
            // 第二级流水线复位
            data_stage2 <= 0;
            addr_stage2 <= 0;
            valid_stage2 <= 0;
            en_stage2 <= 0;
            
            // 输出级复位
            data_out <= 0;
            valid_out <= 0;
            
            // 反压逻辑复位
            ready_out <= 1'b1;
        end
        else begin
            // 第一级流水线逻辑
            if (ready_out) begin
                data_stage1 <= data_in;
                addr_stage1 <= addr;
                valid_stage1 <= valid_in;
                en_stage1 <= en;
            end
            
            // 第二级流水线逻辑
            data_stage2 <= data_stage1;
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            en_stage2 <= en_stage1;
            
            // 输出级 - 解复用逻辑
            valid_out <= valid_stage2;
            if (en_stage2 && valid_stage2) begin
                data_out <= 0;
                data_out[addr_stage2] <= data_stage2;
            end
            
            // 反压逻辑
            ready_out <= 1'b1; // 始终准备接收，可根据需要修改为更复杂的反压逻辑
        end
    end

endmodule