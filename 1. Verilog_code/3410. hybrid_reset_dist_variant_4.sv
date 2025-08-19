//SystemVerilog
//IEEE 1364-2005 Verilog
module hybrid_reset_dist(
    input wire clk,
    input wire async_rst,
    input wire sync_rst,
    input wire [3:0] mode_select,
    output reg [3:0] reset_out
);
    // 流水线阶段1寄存器
    reg sync_rst_stage1;
    reg [3:0] mode_select_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg [3:0] reset_value_stage2;
    reg valid_stage2;
    
    // 阶段1: 捕获输入并同步
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync_rst_stage1 <= 1'b0;
            mode_select_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
        end
        else begin
            sync_rst_stage1 <= sync_rst;
            mode_select_stage1 <= mode_select;
            valid_stage1 <= 1'b1; // 数据有效信号
        end
    end
    
    // 阶段2: 计算复位值
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            reset_value_stage2 <= 4'hF;
            valid_stage2 <= 1'b0;
        end
        else begin
            if (valid_stage1) begin
                reset_value_stage2 <= sync_rst_stage1 ? (mode_select_stage1 & 4'hF) : 4'h0;
                valid_stage2 <= 1'b1;
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 阶段3: 输出寄存器
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            reset_out <= 4'hF; // 异步复位优先级最高
        end
        else begin
            if (valid_stage2) begin
                reset_out <= reset_value_stage2;
            end
        end
    end
endmodule