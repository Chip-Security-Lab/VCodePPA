//SystemVerilog
module pl_reg_sync #(parameter W=8, parameter PIPELINE_STAGES=6) (
    input clk,                  // 时钟信号
    input rst_n,                // 低电平有效复位信号
    input en,                   // 使能信号
    input valid_in,             // 输入有效信号
    output ready_out,           // 输出就绪信号
    input [W-1:0] data_in,      // 数据输入
    output reg [W-1:0] data_out, // 数据输出
    output reg valid_out        // 输出有效信号
);

    // 流水线阶段寄存器 - 增加到5级
    reg [W-1:0] data_stage1, data_stage2, data_stage3, data_stage4, data_stage5;
    
    // 流水线控制信号 - 增加到5级
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    reg ready_stage1, ready_stage2, ready_stage3, ready_stage4, ready_stage5, ready_stage6;
    
    // 缓存输入数据和控制信号以实现前向寄存器重定时
    reg [W-1:0] data_in_reg;
    reg valid_in_reg, en_reg;
    
    // 流水线就绪信号生成（向后传播）
    assign ready_out = ready_stage1;
    
    // 输入寄存器 - 移动到数据路径前端
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {W{1'b0}};
            valid_in_reg <= 1'b0;
            en_reg <= 1'b0;
        end
        else begin
            data_in_reg <= data_in;
            valid_in_reg <= valid_in;
            en_reg <= en;
        end
    end
    
    // 主流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位流水线寄存器
            data_stage1 <= {W{1'b0}};
            data_stage2 <= {W{1'b0}};
            data_stage3 <= {W{1'b0}};
            data_stage4 <= {W{1'b0}};
            data_stage5 <= {W{1'b0}};
            data_out <= {W{1'b0}};
            
            // 复位控制信号
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            valid_stage5 <= 1'b0;
            valid_out <= 1'b0;
            
            ready_stage1 <= 1'b1;
            ready_stage2 <= 1'b1;
            ready_stage3 <= 1'b1;
            ready_stage4 <= 1'b1;
            ready_stage5 <= 1'b1;
            ready_stage6 <= 1'b1;
        end
        else begin
            // 控制信号流水线 - 使用寄存器后的输入信号
            valid_stage1 <= valid_in_reg & en_reg & ready_stage1;
            valid_stage2 <= valid_stage1 & ready_stage2;
            valid_stage3 <= valid_stage2 & ready_stage3;
            valid_stage4 <= valid_stage3 & ready_stage4;
            valid_stage5 <= valid_stage4 & ready_stage5;
            valid_out <= valid_stage5 & ready_stage6;
            
            // 数据流水线 - 使用寄存器后的数据
            if (valid_in_reg & en_reg & ready_stage1)
                data_stage1 <= data_in_reg;
                
            if (valid_stage1 & ready_stage2)
                data_stage2 <= data_stage1;
                
            if (valid_stage2 & ready_stage3)
                data_stage3 <= data_stage2;
                
            if (valid_stage3 & ready_stage4)
                data_stage4 <= data_stage3;
                
            if (valid_stage4 & ready_stage5)
                data_stage5 <= data_stage4;
                
            if (valid_stage5 & ready_stage6)
                data_out <= data_stage5;
        end
    end
    
endmodule