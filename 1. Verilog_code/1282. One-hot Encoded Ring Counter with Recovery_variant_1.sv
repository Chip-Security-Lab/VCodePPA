//SystemVerilog
module one_hot_ring_counter(
    input wire clk,
    input wire rst_n,
    input wire enable,  // 添加使能信号控制流水线
    output reg [3:0] one_hot,
    output reg valid_out
);
    // 内部流水线寄存器
    reg [3:0] stage1_one_hot;
    reg [3:0] stage2_one_hot;
    reg valid_stage1, valid_stage2;
    
    // 第一阶段：重置逻辑和初始化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_one_hot <= 4'b0001;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            stage1_one_hot <= (one_hot == 4'b0000) ? 4'b0001 : 
                             {one_hot[2:0], one_hot[3]};
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二阶段：中间处理阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_one_hot <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            stage2_one_hot <= stage1_one_hot;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 最终输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot <= 4'b0001;
            valid_out <= 1'b0;
        end else begin
            one_hot <= stage2_one_hot;
            valid_out <= valid_stage2;
        end
    end
endmodule