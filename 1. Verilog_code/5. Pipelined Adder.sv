module pipelined_adder (
    input clk,
    input [3:0] a, b,
    output reg [3:0] sum
);
    reg [3:0] stage1_a, stage1_b;
    reg [3:0] stage2_sum;

    always @(posedge clk) begin
        stage1_a <= a;
        stage1_b <= b;
    end

    always @(posedge clk) begin
        stage2_sum <= stage1_a + stage1_b;
    end

    always @(posedge clk) begin
        sum <= stage2_sum;
    end
endmodule