//SystemVerilog
module shadow_reg_pipeline #(parameter DW=8) (
    input wire clk,
    input wire rst_n,        // 添加复位信号
    input wire en,
    input wire valid_in,     // 添加输入有效信号
    output wire ready_out,   // 添加就绪信号
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid_out     // 添加输出有效信号
);
    // 流水线寄存器和控制信号
    reg [DW-1:0] stage1_data;
    reg [DW-1:0] stage2_data;
    reg [DW-1:0] stage3_data;
    
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 就绪信号逻辑 - 简单实现，可根据背压需求扩展
    assign ready_out = 1'b1;
    
    // 第一级流水线 - 输入到阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en && valid_in && ready_out) begin
            stage1_data <= data_in;
            valid_stage1 <= 1'b1;
        end else if (en && !valid_in) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 阶段1到阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (en) begin
            stage2_data <= stage1_data;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 阶段2到阶段3/输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (en) begin
            stage3_data <= stage2_data;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else if (en) begin
            data_out <= stage3_data;
            valid_out <= valid_stage3;
        end
    end
    
endmodule