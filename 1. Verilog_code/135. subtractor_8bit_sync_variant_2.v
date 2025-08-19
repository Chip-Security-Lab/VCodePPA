module subtractor_8bit_sync (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);

    reg [7:0] diff_reg;
    wire [7:0] diff_wire;
    wire [7:0] b_comp;
    wire [7:0] sum;
    wire carry;

    // 优化减法运算：使用补码加法实现
    assign b_comp = ~b + 1'b1;  // 取反加1得到补码
    assign {carry, sum} = a + b_comp;
    assign diff_wire = sum;

    // 同步寄存器
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            diff_reg <= 8'b0;
        end else begin
            diff_reg <= diff_wire;
        end
    end

    assign diff = diff_reg;

endmodule