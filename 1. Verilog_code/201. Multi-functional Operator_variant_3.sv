//SystemVerilog
// 顶层模块
module multi_function_operator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,
    output reg [15:0] result,
    output reg valid
);

    // 内部信号
    wire [15:0] add_result;
    wire [15:0] sub_result;
    wire [15:0] mul_result;
    wire [15:0] div_result;
    wire add_valid, sub_valid, mul_valid, div_valid;

    // 实例化加法器模块
    adder u_adder (
        .a(a),
        .b(b),
        .result(add_result),
        .valid(add_valid)
    );

    // 实例化减法器模块
    subtractor u_subtractor (
        .a(a),
        .b(b),
        .result(sub_result),
        .valid(sub_valid)
    );

    // 实例化乘法器模块
    multiplier u_multiplier (
        .a(a),
        .b(b),
        .result(mul_result),
        .valid(mul_valid)
    );

    // 实例化除法器模块
    divider u_divider (
        .a(a),
        .b(b),
        .result(div_result),
        .valid(div_valid)
    );

    // 结果选择逻辑
    always @(*) begin
        case (op_select)
            2'b00: begin
                result = add_result;
                valid = add_valid;
            end
            2'b01: begin
                result = sub_result;
                valid = sub_valid;
            end
            2'b10: begin
                result = mul_result;
                valid = mul_valid;
            end
            2'b11: begin
                result = div_result;
                valid = div_valid;
            end
            default: begin
                result = 16'b0;
                valid = 1'b0;
            end
        endcase
    end
endmodule

// 加法器模块
module adder (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result,
    output reg valid
);
    always @(*) begin
        result = a + b;
        valid = 1'b1;
    end
endmodule

// 减法器模块
module subtractor (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result,
    output reg valid
);
    always @(*) begin
        result = a - b;
        valid = 1'b1;
    end
endmodule

// 乘法器模块
module multiplier (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result,
    output reg valid
);
    reg [15:0] partial_product [0:7];
    reg [15:0] sum;
    integer i;

    always @(*) begin
        // Baugh-Wooley multiplication
        for (i = 0; i < 8; i = i + 1) begin
            partial_product[i] = (b[i] ? (a << i) : 16'b0);
        end

        // Summing partial products
        sum = 16'b0;
        for (i = 0; i < 8; i = i + 1) begin
            sum = sum + partial_product[i];
        end

        result = sum;
        valid = 1'b1;
    end
endmodule

// 除法器模块
module divider (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result,
    output reg valid
);
    always @(*) begin
        if (b != 0) begin
            result = a / b;
            valid = 1'b1;
        end else begin
            result = 16'b0;
            valid = 1'b0;
        end
    end
endmodule