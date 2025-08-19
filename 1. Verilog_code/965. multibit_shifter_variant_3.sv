//SystemVerilog
module multibit_shifter (
    input clk, reset,
    input [1:0] data_in,
    input valid_in,         // 输入数据有效信号
    output reg [1:0] data_out,
    output reg valid_out,   // 输出数据有效信号
    output reg ready_in     // 输入就绪信号
);
    // 流水线寄存器声明
    reg [1:0] stage1_data, stage2_data, stage3_data;
    reg [1:0] stage1_reg, stage2_reg, stage3_reg;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 就绪信号逻辑 - 始终准备接收新数据
    always @(*) begin
        ready_in = 1'b1;
    end
    
    // 第一级流水线 - 接收输入数据
    always @(posedge clk) begin
        if (reset) begin
            stage1_data <= 2'h0;
            valid_stage1 <= 1'b0;
        end
        else if (valid_in && ready_in) begin
            stage1_data <= data_in;
            valid_stage1 <= 1'b1;
        end
        else if (!valid_in) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 第一次移位
    always @(posedge clk) begin
        if (reset) begin
            stage1_reg <= 2'h0;
            stage2_data <= 2'h0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            stage1_reg <= stage1_data;
            stage2_data <= stage1_reg;
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 第三级流水线 - 第二次移位
    always @(posedge clk) begin
        if (reset) begin
            stage2_reg <= 2'h0;
            stage3_data <= 2'h0;
            valid_stage3 <= 1'b0;
        end
        else if (valid_stage2) begin
            stage2_reg <= stage2_data;
            stage3_data <= stage2_reg;
            valid_stage3 <= valid_stage2;
        end
        else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // 输出阶段 - 最终结果输出
    always @(posedge clk) begin
        if (reset) begin
            stage3_reg <= 2'h0;
            data_out <= 2'h0;
            valid_out <= 1'b0;
        end
        else if (valid_stage3) begin
            stage3_reg <= stage3_data;
            data_out <= stage3_reg;
            valid_out <= valid_stage3;
        end
        else begin
            valid_out <= 1'b0;
        end
    end
endmodule