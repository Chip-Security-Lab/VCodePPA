//SystemVerilog
// -----------------------------------------------------------------------------
// Top-Level SIPO Register Pipeline Module
// Structured pipelined dataflow for SIPO and subtractor
// -----------------------------------------------------------------------------
module sipo_register(
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        serial_in,
    output wire [7:0]  parallel_out
);

    // Stage 1: Serial Shift Register
    wire [7:0] stage1_shift_data;

    sipo_shift_stage #(
        .WIDTH(8)
    ) u_sipo_shift_stage (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .serial_in(serial_in),
        .shift_data_out(stage1_shift_data)
    );

    // Stage 2: Register between Shift and Subtractor
    wire [7:0] stage2_shift_data_reg;
    pipeline_reg #(
        .WIDTH(8)
    ) u_pipeline_reg_shift_sub (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .data_in(stage1_shift_data),
        .data_out(stage2_shift_data_reg)
    );

    // Stage 3: Subtraction Stage (Minuend - Subtrahend)
    wire [7:0] stage3_sub_result;

    subtractor_stage #(
        .WIDTH(8)
    ) u_subtractor_stage (
        .clk(clk),
        .rst(rst),
        .minuend_in(stage2_shift_data_reg),
        .subtrahend_const(8'b00001111), // Example subtrahend for demonstration
        .sub_result_out(stage3_sub_result)
    );

    // Stage 4: Output Latch
    pipeline_reg #(
        .WIDTH(8)
    ) u_pipeline_reg_output (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .data_in(stage3_sub_result),
        .data_out(parallel_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Stage 1: Serial-In Parallel-Out Shift Register
// -----------------------------------------------------------------------------
module sipo_shift_stage #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,
    input  wire             serial_in,
    output reg  [WIDTH-1:0] shift_data_out
);
    always @(posedge clk) begin
        if (rst)
            shift_data_out <= {WIDTH{1'b0}};
        else if (enable)
            shift_data_out <= {shift_data_out[WIDTH-2:0], serial_in};
    end
endmodule

// -----------------------------------------------------------------------------
// Generic Pipeline Register for Dataflow Stages
// -----------------------------------------------------------------------------
module pipeline_reg #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= {WIDTH{1'b0}};
        else if (enable)
            data_out <= data_in;
    end
endmodule

// -----------------------------------------------------------------------------
// Stage 3: Subtractor Pipeline Stage (minuend - subtrahend)
// -----------------------------------------------------------------------------
module subtractor_stage #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] minuend_in,
    input  wire [WIDTH-1:0] subtrahend_const,
    output reg  [WIDTH-1:0] sub_result_out
);

    // Pipeline for input operands
    reg [WIDTH-1:0] minuend_reg;
    reg [WIDTH-1:0] subtrahend_reg;
    wire [WIDTH-1:0] diff_wire;

    always @(posedge clk) begin
        if (rst) begin
            minuend_reg    <= {WIDTH{1'b0}};
            subtrahend_reg <= {WIDTH{1'b0}};
        end else begin
            minuend_reg    <= minuend_in;
            subtrahend_reg <= subtrahend_const;
        end
    end

    // Subtract in combinational logic
    conditional_sum_subtractor_8bit u_conditional_sum_subtractor_8bit (
        .a(minuend_reg),
        .b(subtrahend_reg),
        .diff(diff_wire)
    );

    // Pipeline result to output register
    always @(posedge clk) begin
        if (rst)
            sub_result_out <= {WIDTH{1'b0}};
        else
            sub_result_out <= diff_wire;
    end

endmodule

// -----------------------------------------------------------------------------
// 8-bit Conditional Sum Subtractor
// -----------------------------------------------------------------------------
module conditional_sum_subtractor_8bit(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff
);
    wire [7:0] b_inverted;
    wire       carry_in;
    wire [7:0] sum;

    assign b_inverted = ~b;
    assign carry_in = 1'b1; // For two's complement subtraction

    conditional_sum_adder_8bit u_conditional_sum_adder_8bit (
        .a(a),
        .b(b_inverted),
        .cin(carry_in),
        .sum(sum),
        .cout()
    );

    assign diff = sum;
endmodule

// -----------------------------------------------------------------------------
// 8-bit Conditional Sum Adder
// -----------------------------------------------------------------------------
module conditional_sum_adder_8bit(
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [3:0] sum_low_0, sum_low_1, sum_high_0, sum_high_1;
    wire       carry_low_0, carry_low_1, carry_high_0, carry_high_1;
    wire       carry_low;

    // Lower 4 bits (bits 3:0)
    conditional_sum_adder_4bit u_csa4_low_0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(1'b0),
        .sum(sum_low_0),
        .cout(carry_low_0)
    );
    conditional_sum_adder_4bit u_csa4_low_1 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(1'b1),
        .sum(sum_low_1),
        .cout(carry_low_1)
    );

    assign sum[3:0] = (cin == 1'b0) ? sum_low_0 : sum_low_1;
    assign carry_low = (cin == 1'b0) ? carry_low_0 : carry_low_1;

    // Upper 4 bits (bits 7:4)
    conditional_sum_adder_4bit u_csa4_high_0 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(1'b0),
        .sum(sum_high_0),
        .cout(carry_high_0)
    );
    conditional_sum_adder_4bit u_csa4_high_1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(1'b1),
        .sum(sum_high_1),
        .cout(carry_high_1)
    );

    assign sum[7:4] = (carry_low == 1'b0) ? sum_high_0 : sum_high_1;
    assign cout = (carry_low == 1'b0) ? carry_high_0 : carry_high_1;
endmodule

// -----------------------------------------------------------------------------
// 4-bit Conditional Sum Adder
// -----------------------------------------------------------------------------
module conditional_sum_adder_4bit(
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [3:0] sum_0, sum_1;
    wire       carry_0, carry_1;

    ripple_carry_adder_4bit u_rca4_0 (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(sum_0),
        .cout(carry_0)
    );
    ripple_carry_adder_4bit u_rca4_1 (
        .a(a),
        .b(b),
        .cin(1'b1),
        .sum(sum_1),
        .cout(carry_1)
    );

    assign sum  = (cin == 1'b0) ? sum_0 : sum_1;
    assign cout = (cin == 1'b0) ? carry_0 : carry_1;
endmodule

// -----------------------------------------------------------------------------
// 4-bit Ripple Carry Adder
// -----------------------------------------------------------------------------
module ripple_carry_adder_4bit(
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire c1, c2, c3;

    full_adder u_fa0 (
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .sum(sum[0]),
        .cout(c1)
    );
    full_adder u_fa1 (
        .a(a[1]),
        .b(b[1]),
        .cin(c1),
        .sum(sum[1]),
        .cout(c2)
    );
    full_adder u_fa2 (
        .a(a[2]),
        .b(b[2]),
        .cin(c2),
        .sum(sum[2]),
        .cout(c3)
    );
    full_adder u_fa3 (
        .a(a[3]),
        .b(b[3]),
        .cin(c3),
        .sum(sum[3]),
        .cout(cout)
    );
endmodule

// -----------------------------------------------------------------------------
// 1-bit Full Adder
// -----------------------------------------------------------------------------
module full_adder(
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule