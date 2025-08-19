//SystemVerilog
module dual_sampler (
    input wire clk,
    input wire din,
    output reg rise_data,
    output reg fall_data
);
    // 增加流水线级数
    // 输入端寄存器级
    reg din_stage1;
    reg din_stage2;
    
    // 上升沿采样流水线
    reg rise_data_stage1;
    
    // 下降沿采样流水线
    reg fall_data_stage1;
    
    // 输入端流水线
    always @(posedge clk) begin
        din_stage1 <= din;
        din_stage2 <= din_stage1;
    end
    
    // 上升沿采样流水线
    always @(posedge clk) begin
        rise_data_stage1 <= din_stage2;
        rise_data <= rise_data_stage1;
    end
    
    // 下降沿采样流水线 - 使用输入级寄存器
    always @(negedge clk) begin
        fall_data_stage1 <= din_stage2;
        fall_data <= fall_data_stage1;
    end
endmodule