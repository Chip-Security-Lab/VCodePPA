//SystemVerilog
//IEEE 1364-2005 Verilog
module gamma_pipeline (
    input wire clk,
    input wire rst_n,      // 复位信号
    input wire valid_in,   // 输入有效信号
    input wire [7:0] in,   // 输入数据
    output wire valid_out, // 输出有效信号
    output wire [7:0] out  // 输出数据
);

    // 数据流水线寄存器
    reg [7:0] stage1a_data, stage1b_data;
    reg [7:0] stage2a_data, stage2b_data;
    reg [7:0] stage3a_data, stage3b_data;
    
    // 控制流水线寄存器
    reg valid_stage1a, valid_stage1b;
    reg valid_stage2a, valid_stage2b;
    reg valid_stage3a, valid_stage3b;
    
    // 中间计算结果
    reg [15:0] mult_result;
    reg [7:0] sub_result;
    
    // 流水线第一级A：乘法运算准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1a_data <= 8'h0;
            valid_stage1a <= 1'b0;
        end else begin
            if (valid_in) begin
                stage1a_data <= in;
                valid_stage1a <= 1'b1;
            end else begin
                valid_stage1a <= 1'b0;
            end
        end
    end
    
    // 流水线第一级B：完成乘法运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1b_data <= 8'h0;
            valid_stage1b <= 1'b0;
            mult_result <= 16'h0;
        end else begin
            if (valid_stage1a) begin
                mult_result <= stage1a_data * 2;
                stage1b_data <= stage1a_data * 2;
                valid_stage1b <= 1'b1;
            end else begin
                valid_stage1b <= 1'b0;
            end
        end
    end
    
    // 流水线第二级A：减法运算准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2a_data <= 8'h0;
            valid_stage2a <= 1'b0;
        end else begin
            if (valid_stage1b) begin
                stage2a_data <= stage1b_data;
                valid_stage2a <= 1'b1;
            end else begin
                valid_stage2a <= 1'b0;
            end
        end
    end
    
    // 流水线第二级B：完成减法运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2b_data <= 8'h0;
            valid_stage2b <= 1'b0;
            sub_result <= 8'h0;
        end else begin
            if (valid_stage2a) begin
                sub_result <= stage2a_data - 15;
                stage2b_data <= stage2a_data - 15;
                valid_stage2b <= 1'b1;
            end else begin
                valid_stage2b <= 1'b0;
            end
        end
    end
    
    // 流水线第三级A：移位运算准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3a_data <= 8'h0;
            valid_stage3a <= 1'b0;
        end else begin
            if (valid_stage2b) begin
                stage3a_data <= stage2b_data;
                valid_stage3a <= 1'b1;
            end else begin
                valid_stage3a <= 1'b0;
            end
        end
    end
    
    // 流水线第三级B：完成移位运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3b_data <= 8'h0;
            valid_stage3b <= 1'b0;
        end else begin
            if (valid_stage3a) begin
                stage3b_data <= stage3a_data >> 1;
                valid_stage3b <= 1'b1;
            end else begin
                valid_stage3b <= 1'b0;
            end
        end
    end
    
    // 输出赋值
    assign out = stage3b_data;
    assign valid_out = valid_stage3b;
    
endmodule