//SystemVerilog
module signed_add_shift (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号
    input wire valid_in,      // 输入数据有效信号
    input wire signed [7:0] a,
    input wire signed [7:0] b,
    input wire [2:0] shift_amount,
    output reg signed [7:0] sum,
    output reg signed [7:0] shifted_result,
    output reg valid_out      // 输出数据有效信号
);
    // 第一级流水线信号
    reg signed [7:0] a_reg, b_reg;
    reg [2:0] shift_amount_reg;
    reg valid_stage1;
    
    // 第二级流水线信号
    reg signed [7:0] sum_comb;
    reg signed [7:0] shifted_comb;
    reg valid_stage2;
    
    // 输入级 - 寄存数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            shift_amount_reg <= 3'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            shift_amount_reg <= shift_amount;
            valid_stage1 <= valid_in;
        end
    end
    
    // 计算级 - 执行加法和移位操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_comb <= 8'b0;
            shifted_comb <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            sum_comb <= a_reg + b_reg;
            shifted_comb <= a_reg >>> shift_amount_reg;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级 - 更新输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'b0;
            shifted_result <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            sum <= sum_comb;
            shifted_result <= shifted_comb;
            valid_out <= valid_stage2;
        end
    end
    
endmodule