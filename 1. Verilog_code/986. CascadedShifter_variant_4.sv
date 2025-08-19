//SystemVerilog

module CascadedShifter #(parameter STAGES=3, WIDTH=8) (
    input clk,
    input en,
    input serial_in,
    output serial_out
);
    // High-fanout signal stage_wires is buffered
    wire [STAGES:0] stage_wires_int;
    reg  [STAGES:0] stage_wires_buf1;
    reg  [STAGES:0] stage_wires_buf2;

    assign stage_wires_int[0] = serial_in;

    // Buffer stage_wires in two pipeline stages to reduce fanout and balance load
    always @(posedge clk) begin
        if (en) begin
            stage_wires_buf1 <= stage_wires_int;
            stage_wires_buf2 <= stage_wires_buf1;
        end
    end

    genvar i;
    generate
        for(i=0; i<STAGES; i=i+1) begin : STAGE_GEN
            ShiftStage_PPAdder #(.WIDTH(WIDTH)) stage_inst (
                .clk(clk),
                .en(en),
                .in(stage_wires_buf2[i]),
                .out(stage_wires_int[i+1])
            );
        end
    endgenerate

    assign serial_out = stage_wires_buf2[STAGES];
endmodule

module ShiftStage_PPAdder #(parameter WIDTH=8) (
    input clk,
    input en,
    input in,
    output reg out
);
    reg [WIDTH-1:0] shift_buffer;
    wire [WIDTH-1:0] add_result;
    reg [WIDTH-1:0] addend;
    reg [WIDTH-1:0] adder_input;
    reg [WIDTH-1:0] sum_reg;

    // Parallel Prefix Adder instance (Kogge-Stone 8-bit)
    ParallelPrefixAdder8 ppa_inst (
        .a(shift_buffer),
        .b(addend),
        .sum(add_result)
    );

    always @(posedge clk) begin
        if (en) begin
            adder_input <= {shift_buffer[WIDTH-2:0], in};
            addend <= {WIDTH{1'b0}}; // No carry-in for shift, as shift is like add zero
            shift_buffer <= add_result;
            sum_reg <= add_result;
        end
        out <= sum_reg[WIDTH-1];
    end
endmodule

module ParallelPrefixAdder8 (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] sum
);
    // Kogge-Stone Parallel Prefix Adder Implementation
    wire [7:0] g0, p0;
    wire [7:0] g1, p1;
    wire [7:0] g2, p2;
    wire [7:0] g3, p3;
    wire [7:0] c;

    // Stage 0: Generate and Propagate
    assign g0 = a & b;
    assign p0 = a ^ b;

    // Stage 1
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0[1] | (p0[1] & g0[0]);
    assign p1[1] = p0[1] & p0[0];
    assign g1[2] = g0[2] | (p0[2] & g0[1]);
    assign p1[2] = p0[2] & p0[1];
    assign g1[3] = g0[3] | (p0[3] & g0[2]);
    assign p1[3] = p0[3] & p0[2];
    assign g1[4] = g0[4] | (p0[4] & g0[3]);
    assign p1[4] = p0[4] & p0[3];
    assign g1[5] = g0[5] | (p0[5] & g0[4]);
    assign p1[5] = p0[5] & p0[4];
    assign g1[6] = g0[6] | (p0[6] & g0[5]);
    assign p1[6] = p0[6] & p0[5];
    assign g1[7] = g0[7] | (p0[7] & g0[6]);
    assign p1[7] = p0[7] & p0[6];

    // Stage 2
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Stage 3
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3] | (p2[3] & g2[0]);
    assign p3[3] = p2[3] & p2[0];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign p3[6] = p2[6] & p2[2];
    assign g3[7] = g2[7] | (p2[7] & g2[3]);
    assign p3[7] = p2[7] & p2[3];

    // Carry generation
    assign c[0] = 1'b0;
    assign c[1] = g3[0];
    assign c[2] = g3[1];
    assign c[3] = g3[2];
    assign c[4] = g3[3];
    assign c[5] = g3[4];
    assign c[6] = g3[5];
    assign c[7] = g3[6];

    // Final sum
    assign sum[0] = p0[0] ^ c[0];
    assign sum[1] = p0[1] ^ c[1];
    assign sum[2] = p0[2] ^ c[2];
    assign sum[3] = p0[3] ^ c[3];
    assign sum[4] = p0[4] ^ c[4];
    assign sum[5] = p0[5] ^ c[5];
    assign sum[6] = p0[6] ^ c[6];
    assign sum[7] = p0[7] ^ c[7];
endmodule