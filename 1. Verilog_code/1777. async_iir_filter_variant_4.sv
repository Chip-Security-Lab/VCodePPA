//SystemVerilog
module async_iir_filter #(
    parameter DW = 14
)(
    input wire clk,                 // 时钟输入
    input wire rst_n,               // 复位信号
    input wire data_valid_in,       // 输入有效信号
    input wire [DW-1:0] x_in,
    input wire [DW-1:0] y_prev,
    input wire [DW-1:0] a_coeff, b_coeff,
    output reg [DW-1:0] y_out,
    output reg data_valid_out       // 输出有效信号
);
    // 声明流水线阶段寄存器
    reg [DW-1:0] x_in_reg, y_prev_reg;
    reg [DW-1:0] a_coeff_reg, b_coeff_reg;
    reg data_valid_stage1;
    
    // 乘法结果寄存器
    reg [2*DW-1:0] prod1_reg, prod2_reg;
    reg data_valid_stage2;
    
    // 增加额外流水线阶段，切分乘法和加法之间的关键路径
    reg [DW-1:0] prod1_high_reg, prod2_high_reg;
    reg data_valid_stage3;
    
    // 第一阶段：输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_in_reg <= {DW{1'b0}};
            y_prev_reg <= {DW{1'b0}};
            a_coeff_reg <= {DW{1'b0}};
            b_coeff_reg <= {DW{1'b0}};
            data_valid_stage1 <= 1'b0;
        end else begin
            x_in_reg <= x_in;
            y_prev_reg <= y_prev;
            a_coeff_reg <= a_coeff;
            b_coeff_reg <= b_coeff;
            data_valid_stage1 <= data_valid_in;
        end
    end
    
    // 第二阶段：乘法操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod1_reg <= {2*DW{1'b0}};
            prod2_reg <= {2*DW{1'b0}};
            data_valid_stage2 <= 1'b0;
        end else begin
            prod1_reg <= a_coeff_reg * x_in_reg;
            prod2_reg <= b_coeff_reg * y_prev_reg;
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // 第三阶段：提取高位进行下一阶段处理，切分关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod1_high_reg <= {DW{1'b0}};
            prod2_high_reg <= {DW{1'b0}};
            data_valid_stage3 <= 1'b0;
        end else begin
            prod1_high_reg <= prod1_reg[2*DW-1:DW];
            prod2_high_reg <= prod2_reg[2*DW-1:DW];
            data_valid_stage3 <= data_valid_stage2;
        end
    end
    
    // 第四阶段：加法操作和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= {DW{1'b0}};
            data_valid_out <= 1'b0;
        end else begin
            y_out <= prod1_high_reg + prod2_high_reg;
            data_valid_out <= data_valid_stage3;
        end
    end

endmodule