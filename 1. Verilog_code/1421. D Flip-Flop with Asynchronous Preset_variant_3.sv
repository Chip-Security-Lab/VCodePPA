//SystemVerilog
module d_ff_async_preset_pipelined (
    input wire clk,
    input wire rst_n,
    input wire preset_n,
    input wire d_in,
    input wire valid_in,
    output wire ready_out,
    output reg d_out,
    output reg valid_out
);
    // 流水线阶段1寄存器
    reg d_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg d_stage2;
    reg valid_stage2;
    
    // 就绪信号 - 当流水线可以接收新数据时为高
    assign ready_out = 1'b1; // 此流水线始终准备好接收新数据
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n or negedge preset_n) begin
        if (!rst_n) begin
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (!preset_n) begin
            d_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end
        else begin
            d_stage1 <= d_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n or negedge preset_n) begin
        if (!rst_n) begin
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (!preset_n) begin
            d_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end
        else begin
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级
    always @(posedge clk or negedge rst_n or negedge preset_n) begin
        if (!rst_n) begin
            d_out <= 1'b0;
            valid_out <= 1'b0;
        end
        else if (!preset_n) begin
            d_out <= 1'b1;
            valid_out <= 1'b0;
        end
        else begin
            d_out <= d_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule