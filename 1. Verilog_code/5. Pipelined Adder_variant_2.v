// Top level module
module pipelined_adder (
    input clk,
    input [3:0] a, b,
    output [3:0] sum
);

    wire [3:0] stage1_a, stage1_b;
    wire [3:0] stage2_sum;

    // Input stage module
    input_stage input_stage_inst (
        .clk(clk),
        .a(a),
        .b(b),
        .stage1_a(stage1_a),
        .stage1_b(stage1_b)
    );

    // Addition stage module  
    add_stage add_stage_inst (
        .clk(clk),
        .stage1_a(stage1_a),
        .stage1_b(stage1_b),
        .stage2_sum(stage2_sum)
    );

    // Output stage module
    output_stage output_stage_inst (
        .clk(clk),
        .stage2_sum(stage2_sum),
        .sum(sum)
    );

endmodule

// Input stage module
module input_stage (
    input clk,
    input [3:0] a, b,
    output reg [3:0] stage1_a, stage1_b
);

    always @(posedge clk) begin
        stage1_a <= a;
        stage1_b <= b;
    end

endmodule

// Addition stage module
module add_stage (
    input clk,
    input [3:0] stage1_a, stage1_b,
    output reg [3:0] stage2_sum
);

    always @(posedge clk) begin
        stage2_sum <= stage1_a + stage1_b;
    end

endmodule

// Output stage module
module output_stage (
    input clk,
    input [3:0] stage2_sum,
    output reg [3:0] sum
);

    always @(posedge clk) begin
        sum <= stage2_sum;
    end

endmodule