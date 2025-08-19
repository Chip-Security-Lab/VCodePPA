//SystemVerilog
module shadow_reg_delayed_rst #(parameter DW=16, DELAY=3, PIPELINE_STAGES=3) (
    input clk, rst_in,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // 优化复位移位寄存器实现
    reg [DELAY-1:0] rst_sr;
    wire rst_active;
    
    // 优化流水线寄存器实现
    reg [DW-1:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 复位信号逻辑优化
    assign rst_active = |rst_sr;
    
    always @(posedge clk) begin
        // 延迟复位寄存器
        rst_sr <= {rst_sr[DELAY-2:0], rst_in};
        
        // 流水线寄存器 - 条件语句重组以改善时序
        if (rst_active) begin
            // 复位状态 - 流水线全部清零
            data_stage1 <= {DW{1'b0}};
            data_stage2 <= {DW{1'b0}};
            data_out <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            // 正常操作状态 - 数据流转
            data_stage1 <= data_in;
            data_stage2 <= data_stage1;
            data_out <= data_stage2;
            valid_stage1 <= 1'b1;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
endmodule