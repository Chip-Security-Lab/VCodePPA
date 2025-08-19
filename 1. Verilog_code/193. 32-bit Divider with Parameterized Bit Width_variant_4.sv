//SystemVerilog
module divider_param #(
    parameter WIDTH = 32
)(
    input                  clk,        // 添加时钟信号
    input                  rst_n,      // 添加复位信号
    input                  valid_in,   // 添加输入有效信号
    input      [WIDTH-1:0] dividend,   // 被除数
    input      [WIDTH-1:0] divisor,    // 除数
    output reg             valid_out,  // 添加输出有效信号
    output reg [WIDTH-1:0] quotient,   // 商
    output reg [WIDTH-1:0] remainder   // 余数
);

    // 流水线阶段1: 输入寄存器和零检测
    reg [WIDTH-1:0] dividend_r1, divisor_r1;
    reg             valid_r1;
    reg             divisor_is_zero_r1;
    
    // 流水线阶段2: 中间结果
    reg [WIDTH-1:0] quotient_r2, remainder_r2;
    reg             valid_r2;
    reg             divisor_is_zero_r2;
    
    // 流水线阶段1: 捕获输入并检测除数是否为零
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_r1 <= {WIDTH{1'b0}};
            divisor_r1 <= {WIDTH{1'b0}};
            valid_r1 <= 1'b0;
            divisor_is_zero_r1 <= 1'b0;
        end else begin
            dividend_r1 <= dividend;
            divisor_r1 <= divisor;
            valid_r1 <= valid_in;
            divisor_is_zero_r1 <= (divisor == {WIDTH{1'b0}});
        end
    end
    
    // 流水线阶段2: 执行除法运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_r2 <= {WIDTH{1'b0}};
            remainder_r2 <= {WIDTH{1'b0}};
            valid_r2 <= 1'b0;
            divisor_is_zero_r2 <= 1'b0;
        end else begin
            valid_r2 <= valid_r1;
            divisor_is_zero_r2 <= divisor_is_zero_r1;
            
            if (valid_r1) begin
                if (divisor_is_zero_r1) begin
                    // 除数为零处理
                    quotient_r2 <= {WIDTH{1'b1}}; // 全1表示错误
                    remainder_r2 <= dividend_r1;  // 余数等于被除数
                end else begin
                    // 正常除法
                    quotient_r2 <= dividend_r1 / divisor_r1;
                    remainder_r2 <= dividend_r1 % divisor_r1;
                end
            end
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= {WIDTH{1'b0}};
            remainder <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_r2;
            quotient <= quotient_r2;
            remainder <= remainder_r2;
        end
    end

endmodule