module subtractor_4bit_sync (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] diff
);

    wire [3:0] sub_result;
    reg [3:0] a_reg, b_reg;

    // 减法运算子模块
    subtractor_4bit sub_unit (
        .a(a_reg),
        .b(b_reg),
        .diff(sub_result)
    );

    // 输入寄存器
    always @(posedge clk or posedge reset) begin
        a_reg <= (reset) ? 4'b0 : a;
        b_reg <= (reset) ? 4'b0 : b;
    end

    // 输出寄存器
    always @(posedge clk or posedge reset) begin
        diff <= (reset) ? 4'b0 : sub_result;
    end

endmodule

// 纯组合逻辑减法器子模块
module subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);
    assign diff = a - b;
endmodule