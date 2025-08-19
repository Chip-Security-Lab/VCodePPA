//SystemVerilog
// 顶层模块
module multiply_divide_operator (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [7:0] a,
    input [7:0] b,
    output valid_out,
    input ready_in,
    output [15:0] product,
    output [7:0] quotient,
    output [7:0] remainder
);

    // 内部信号
    wire mult_valid;
    wire mult_ready;
    wire div_valid;
    wire div_ready;
    wire rem_valid;
    wire rem_ready;
    
    // 实例化各个子模块
    multiplier mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .operand_a(a),
        .operand_b(b),
        .valid_out(mult_valid),
        .ready_in(mult_ready),
        .result(product)
    );
    
    divider div_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(div_valid),
        .dividend(a),
        .divisor(b),
        .valid_out(div_valid),
        .ready_in(div_ready),
        .quotient(quotient)
    );
    
    remainder_calc rem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(rem_valid),
        .dividend(a),
        .divisor(b),
        .valid_out(rem_valid),
        .ready_in(rem_ready),
        .remainder(remainder)
    );

    // 输出valid信号组合逻辑
    assign valid_out = mult_valid & div_valid & rem_valid;
    
    // 输出ready信号组合逻辑
    assign mult_ready = ready_in;
    assign div_ready = ready_in;
    assign rem_ready = ready_in;

endmodule

// 乘法器子模块
module multiplier #(
    parameter WIDTH_A = 8,
    parameter WIDTH_B = 8,
    parameter WIDTH_RESULT = 16
)(
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [WIDTH_A-1:0] operand_a,
    input [WIDTH_B-1:0] operand_b,
    output valid_out,
    input ready_in,
    output reg [WIDTH_RESULT-1:0] result
);

    // 内部状态寄存器
    reg [WIDTH_RESULT-1:0] result_reg;
    reg valid_reg;
    
    // 组合逻辑
    assign ready_out = !valid_reg | ready_in;
    assign valid_out = valid_reg;
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 0;
            valid_reg <= 0;
        end else begin
            if (valid_in & ready_out) begin
                result_reg <= operand_a * operand_b;
                valid_reg <= 1;
            end else if (ready_in) begin
                valid_reg <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        result <= result_reg;
    end

endmodule

// 除法器子模块
module divider #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output valid_out,
    input ready_in,
    output reg [WIDTH-1:0] quotient
);

    // 内部状态寄存器
    reg [WIDTH-1:0] quotient_reg;
    reg valid_reg;
    
    // 组合逻辑
    assign ready_out = !valid_reg | ready_in;
    assign valid_out = valid_reg;
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_reg <= 0;
            valid_reg <= 0;
        end else begin
            if (valid_in & ready_out) begin
                quotient_reg <= dividend / divisor;
                valid_reg <= 1;
            end else if (ready_in) begin
                valid_reg <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        quotient <= quotient_reg;
    end

endmodule

// 取余子模块
module remainder_calc #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output valid_out,
    input ready_in,
    output reg [WIDTH-1:0] remainder
);

    // 内部状态寄存器
    reg [WIDTH-1:0] remainder_reg;
    reg valid_reg;
    
    // 组合逻辑
    assign ready_out = !valid_reg | ready_in;
    assign valid_out = valid_reg;
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remainder_reg <= 0;
            valid_reg <= 0;
        end else begin
            if (valid_in & ready_out) begin
                remainder_reg <= dividend % divisor;
                valid_reg <= 1;
            end else if (ready_in) begin
                valid_reg <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        remainder <= remainder_reg;
    end

endmodule