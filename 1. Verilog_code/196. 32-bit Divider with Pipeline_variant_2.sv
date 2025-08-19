//SystemVerilog
// 顶层模块
module divider_pipeline_32bit (
    input logic clk,
    input logic rst_n,  // 新增复位信号以提高鲁棒性
    input logic [31:0] dividend,
    input logic [31:0] divisor,
    output logic [31:0] quotient,
    output logic [31:0] remainder,
    output logic valid_out  // 新增输出有效信号
);
    // 内部连线
    logic [31:0] dividend_stage1, divisor_stage1;
    logic valid_stage1;
    
    logic [31:0] quotient_stage2, remainder_stage2;
    logic valid_stage2;
    
    // 实例化流水线阶段模块
    divider_input_stage input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .dividend_in(dividend),
        .divisor_in(divisor),
        .dividend_out(dividend_stage1),
        .divisor_out(divisor_stage1),
        .valid_out(valid_stage1)
    );
    
    divider_computation_stage compute_stage (
        .clk(clk),
        .rst_n(rst_n),
        .dividend_in(dividend_stage1),
        .divisor_in(divisor_stage1),
        .valid_in(valid_stage1),
        .quotient_out(quotient_stage2),
        .remainder_out(remainder_stage2),
        .valid_out(valid_stage2)
    );
    
    divider_output_stage output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .quotient_in(quotient_stage2),
        .remainder_in(remainder_stage2),
        .valid_in(valid_stage2),
        .quotient_out(quotient),
        .remainder_out(remainder),
        .valid_out(valid_out)
    );
    
endmodule

// 输入阶段 - 寄存输入数据并进行预处理
module divider_input_stage #(
    parameter WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    input logic [WIDTH-1:0] dividend_in,
    input logic [WIDTH-1:0] divisor_in,
    output logic [WIDTH-1:0] dividend_out,
    output logic [WIDTH-1:0] divisor_out,
    output logic valid_out
);
    logic divisor_is_zero;
    
    // 检测除数是否为零
    assign divisor_is_zero = (divisor_in == {WIDTH{1'b0}});
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            dividend_out <= {WIDTH{1'b0}};
            divisor_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            dividend_out <= dividend_in;
            divisor_out <= divisor_in;
            valid_out <= ~divisor_is_zero;
        end
    end
endmodule

// 计算阶段 - 优化的除法和取模运算实现
module divider_computation_stage #(
    parameter WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    input logic [WIDTH-1:0] dividend_in,
    input logic [WIDTH-1:0] divisor_in,
    input logic valid_in,
    output logic [WIDTH-1:0] quotient_out,
    output logic [WIDTH-1:0] remainder_out,
    output logic valid_out
);
    // 中间寄存器
    logic [WIDTH-1:0] dividend_abs, divisor_abs;
    logic dividend_sign, divisor_sign, result_sign;
    logic [WIDTH-1:0] quotient_unsigned, remainder_unsigned;
    
    // 符号处理 - 提取符号位并转换为绝对值
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            dividend_abs <= {WIDTH{1'b0}};
            divisor_abs <= {WIDTH{1'b0}};
            dividend_sign <= 1'b0;
            divisor_sign <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // 提取符号（假定有符号数）
            dividend_sign <= dividend_in[WIDTH-1];
            divisor_sign <= divisor_in[WIDTH-1];
            
            // 计算绝对值
            dividend_abs <= dividend_in[WIDTH-1] ? (~dividend_in + 1'b1) : dividend_in;
            divisor_abs <= divisor_in[WIDTH-1] ? (~divisor_in + 1'b1) : divisor_in;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
    
    // 无符号除法运算
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            quotient_unsigned <= {WIDTH{1'b0}};
            remainder_unsigned <= {WIDTH{1'b0}};
            result_sign <= 1'b0;
        end else if (valid_in) begin
            if (valid_in) begin
                quotient_unsigned <= dividend_abs / divisor_abs;
                remainder_unsigned <= dividend_abs % divisor_abs;
                // 商的符号是两个操作数符号的异或
                result_sign <= dividend_sign ^ divisor_sign;
            end else begin
                // 除数为零的情况
                quotient_unsigned <= {WIDTH{1'b1}}; // 全1表示错误
                remainder_unsigned <= dividend_abs;
                result_sign <= dividend_sign;
            end
        end
    end
    
    // 应用符号到最终结果
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            quotient_out <= {WIDTH{1'b0}};
            remainder_out <= {WIDTH{1'b0}};
        end else begin
            // 应用符号到商
            quotient_out <= result_sign ? (~quotient_unsigned + 1'b1) : quotient_unsigned;
            // 余数的符号与被除数相同
            remainder_out <= dividend_sign ? (~remainder_unsigned + 1'b1) : remainder_unsigned;
        end
    end
endmodule

// 输出阶段 - 寄存并输出结果，提供流水线寄存
module divider_output_stage #(
    parameter WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    input logic [WIDTH-1:0] quotient_in,
    input logic [WIDTH-1:0] remainder_in,
    input logic valid_in,
    output logic [WIDTH-1:0] quotient_out,
    output logic [WIDTH-1:0] remainder_out,
    output logic valid_out
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            quotient_out <= {WIDTH{1'b0}};
            remainder_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            quotient_out <= quotient_in;
            remainder_out <= remainder_in;
            valid_out <= valid_in;
        end
    end
endmodule