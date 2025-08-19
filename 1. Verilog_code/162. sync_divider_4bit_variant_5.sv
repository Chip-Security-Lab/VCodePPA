//SystemVerilog
module sync_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient
);

    wire [3:0] div_result;
    wire div_valid;
    wire b_non_zero;

    // 除法计算子模块
    divider_core u_divider_core (
        .a(a),
        .b(b),
        .b_non_zero(b_non_zero),
        .result(div_result),
        .valid(div_valid)
    );

    // 结果同步子模块
    result_sync u_result_sync (
        .clk(clk),
        .reset(reset),
        .div_result(div_result),
        .div_valid(div_valid),
        .quotient(quotient)
    );

endmodule

module divider_core (
    input [3:0] a,
    input [3:0] b,
    output b_non_zero,
    output reg [3:0] result,
    output reg valid
);
    // 提前计算b是否为0
    assign b_non_zero = |b;

    // 预计算除法结果
    wire [3:0] temp_result = a / b;

    always @(*) begin
        if (b_non_zero) begin
            result = temp_result;
            valid = 1'b1;
        end else begin
            result = 4'b0;
            valid = 1'b0;
        end
    end
endmodule

module result_sync (
    input clk,
    input reset,
    input [3:0] div_result,
    input div_valid,
    output reg [3:0] quotient
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            quotient <= 4'b0;
        else if (div_valid)
            quotient <= div_result;
    end
endmodule