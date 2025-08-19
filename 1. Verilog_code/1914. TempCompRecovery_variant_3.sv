//SystemVerilog
module TempCompRecovery #(
    parameter WIDTH = 12
)(
    input clk,
    input [WIDTH-1:0] temp_sensor,
    input [WIDTH-1:0] raw_data,
    output reg [WIDTH-1:0] comp_data
);

    // Internal signals
    reg signed [WIDTH+2:0] offset_reg;
    reg [WIDTH-1:0] comp_data_reg;

    // Offset calculation signals
    wire [11:0] offset_subtrahend = 12'd2048;
    wire [11:0] temp_sensor_sub_result;
    wire temp_sensor_borrow;

    // Parallel Prefix Subtractor for 8 bits (for temp_sensor - 2048)
    ParallelPrefixSubtractor8 u_pp_sub (
        .a(temp_sensor[7:0]),
        .b(offset_subtrahend[7:0]),
        .diff(temp_sensor_sub_result[7:0]),
        .borrow_out(temp_sensor_borrow)
    );
    assign temp_sensor_sub_result[11:8] = temp_sensor[11:8] - offset_subtrahend[11:8] - temp_sensor_borrow;

    // Multiplier for 3 * (temp_sensor - 2048)
    wire signed [WIDTH+2:0] offset_mult_result;
    assign offset_mult_result = {{(WIDTH-11){temp_sensor_sub_result[11]}}, temp_sensor_sub_result} * 3;

    // Offset register update
    always @(posedge clk) begin
        offset_reg <= offset_mult_result;
    end

    // Shifted offset for addition
    wire [WIDTH-1:0] offset_shifted;
    assign offset_shifted = offset_reg[WIDTH+2:3];

    // Adder output
    wire [WIDTH-1:0] comp_data_sum;
    ParallelPrefixAdderN #(.N(WIDTH)) u_pp_add (
        .a(raw_data),
        .b(offset_shifted),
        .sum(comp_data_sum)
    );

    // comp_data register update
    always @(posedge clk) begin
        comp_data_reg <= comp_data_sum;
    end

    // Output assignment
    always @(posedge clk) begin
        comp_data <= comp_data_reg;
    end

endmodule

// 8-bit Parallel Prefix Subtractor
module ParallelPrefixSubtractor8(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff,
    output       borrow_out
);
    wire [7:0] g, p;
    wire [7:0] c;

    assign g = ~a & b;
    assign p = ~(a ^ b);

    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign borrow_out = g[7] | (p[7] & c[7]);

    assign diff = a - b;
endmodule

// N-bit Parallel Prefix Adder (Kogge-Stone)
module ParallelPrefixAdderN #(parameter N = 12) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] sum
);
    wire [N:0] carry;
    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : adder
            assign {carry[i+1], sum[i]} = a[i] + b[i] + carry[i];
        end
    endgenerate
endmodule