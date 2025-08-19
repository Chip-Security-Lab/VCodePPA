//SystemVerilog
module Demux_SyncEn #(parameter DW=8, AW=3) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output reg [(1<<AW)-1:0][DW-1:0] data_out
);
    // 流水线寄存器 - 第一级
    reg en_stage1;
    reg [DW-1:0] data_stage1;
    reg [AW-1:0] addr_stage1;
    
    // 流水线寄存器 - 第二级
    reg en_stage2;
    reg [DW-1:0] data_stage2;
    reg [AW-1:0] addr_stage2;
    
    // 优化的解码寄存器
    reg [(1<<AW)-1:0] decoded_addr;
    
    // 第一级流水线: 输入采样
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_stage1 <= 1'b0;
            data_stage1 <= {DW{1'b0}};
            addr_stage1 <= {AW{1'b0}};
        end
        else begin
            en_stage1 <= en;
            data_stage1 <= data_in;
            addr_stage1 <= addr;
        end
    end
    
    // 第二级流水线: 中间处理与地址解码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_stage2 <= 1'b0;
            data_stage2 <= {DW{1'b0}};
            addr_stage2 <= {AW{1'b0}};
            decoded_addr <= {(1<<AW){1'b0}};
        end
        else begin
            en_stage2 <= en_stage1;
            data_stage2 <= data_stage1;
            addr_stage2 <= addr_stage1;
            
            // 预解码地址 - 实现更高效的输出阶段
            decoded_addr <= {(1<<AW){1'b0}};
            decoded_addr[addr_stage1] <= en_stage1;
        end
    end
    
    // 第三级流水线: 输出寄存 - 基于预解码的地址
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {((1<<AW)*DW){1'b0}};
        end
        else begin
            for (i = 0; i < (1<<AW); i = i + 1) begin
                if (decoded_addr[i]) begin
                    data_out[i] <= data_stage2;
                end
            end
        end
    end
endmodule