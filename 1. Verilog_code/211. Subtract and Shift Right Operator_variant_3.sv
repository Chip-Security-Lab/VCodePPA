//SystemVerilog
module signed_add_shift (
    input  wire        clk,            // 时钟信号
    input  wire        rst_n,          // 复位信号
    input  wire signed [7:0] a,        // 输入操作数 a
    input  wire signed [7:0] b,        // 输入操作数 b
    input  wire [2:0]  shift_amount,   // 移位量
    output reg  signed [7:0] sum,      // 加法结果
    output reg  signed [7:0] shifted_result // 移位结果
);

    // 内部寄存器和信号定义
    reg signed [7:0] a_reg, b_reg;
    reg [2:0] shift_amount_reg;
    reg signed [7:0] add_result_stage1;
    reg signed [7:0] shift_result_stage1;
    
    // 第一流水级：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            shift_amount_reg <= 3'b0;
        end
        else begin
            a_reg <= a;
            b_reg <= b;
            shift_amount_reg <= shift_amount;
        end
    end
    
    // 第二流水级：计算
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            add_result_stage1 <= 8'b0;
            shift_result_stage1 <= 8'b0;
        end
        else begin
            add_result_stage1 <= a_reg + b_reg;
            shift_result_stage1 <= a_reg >>> shift_amount_reg;
        end
    end
    
    // 第三流水级：输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum <= 8'b0;
            shifted_result <= 8'b0;
        end
        else begin
            sum <= add_result_stage1;
            shifted_result <= shift_result_stage1;
        end
    end

endmodule