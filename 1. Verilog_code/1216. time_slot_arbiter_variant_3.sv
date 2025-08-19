//SystemVerilog
module time_slot_arbiter #(
    parameter WIDTH = 4,
    parameter SLOT = 8
) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);

    // 时钟缓冲
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // 缓冲时钟用于不同阶段，减少时钟树负载
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;

    // 流水线阶段1：计数器和轮转逻辑
    reg [7:0] counter_stage1;
    reg [WIDTH-1:0] rotation_stage1;
    reg [WIDTH-1:0] req_stage1;
    reg counter_zero_stage1;
    
    // 对高扇出信号添加缓冲寄存器
    reg [WIDTH-1:0] rotation_stage1_buf1, rotation_stage1_buf2;
    reg [7:0] counter_stage1_buf1, counter_stage1_buf2;
    
    // 流水线阶段2：授权生成逻辑
    reg [WIDTH-1:0] rotation_stage2;
    reg [WIDTH-1:0] req_stage2;
    reg grant_valid_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 流水线阶段1：计数和轮转
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 0;
            rotation_stage1 <= 1;
            req_stage1 <= 0;
            counter_zero_stage1 <= 1;
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= 1;
            counter_stage1 <= (counter_stage1 >= SLOT-1) ? 0 : counter_stage1 + 1;
            counter_zero_stage1 <= (counter_stage1 == SLOT-1) ? 1 : 0;
            
            if (counter_zero_stage1) begin
                rotation_stage1 <= {rotation_stage1[WIDTH-2:0], rotation_stage1[WIDTH-1]};
            end
            
            req_stage1 <= req_i;
        end
    end
    
    // 高扇出信号缓冲 - 第一级缓冲
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            rotation_stage1_buf1 <= 0;
            counter_stage1_buf1 <= 0;
        end else begin
            rotation_stage1_buf1 <= rotation_stage1;
            counter_stage1_buf1 <= counter_stage1;
        end
    end
    
    // 高扇出信号缓冲 - 第二级缓冲
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            rotation_stage1_buf2 <= 0;
            counter_stage1_buf2 <= 0;
        end else begin
            rotation_stage1_buf2 <= rotation_stage1;
            counter_stage1_buf2 <= counter_stage1;
        end
    end
    
    // 流水线阶段2：申请处理和授权生成 - 使用缓冲信号
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            rotation_stage2 <= 0;
            req_stage2 <= 0;
            grant_valid_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            rotation_stage2 <= rotation_stage1_buf1;
            req_stage2 <= req_stage1;
            grant_valid_stage2 <= counter_zero_stage1;
        end
    end
    
    // 输出阶段：生成最终授权信号 - 使用缓冲信号
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
        end else if (valid_stage2) begin
            if (grant_valid_stage2) begin
                grant_o <= (req_stage2 & rotation_stage2) ? rotation_stage2 : 0;
            end
        end
    end
    
endmodule