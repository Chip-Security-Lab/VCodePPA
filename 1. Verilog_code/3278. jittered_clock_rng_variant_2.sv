//SystemVerilog
// Top-level module: Hierarchical jittered clock RNG
module jittered_clock_rng (
    input wire main_clk,
    input wire reset,
    input wire [7:0] jitter_value,
    output wire [15:0] random_out
);

    // Internal signals for inter-module connections
    wire [7:0] counter_value;
    wire capture_bit_signal;
    wire [15:0] random_out_internal;

    // Counter submodule: Handles the counter logic
    counter_unit u_counter (
        .clk(main_clk),
        .rst(reset),
        .counter_out(counter_value)
    );

    // Jitter detector submodule: Detects when to capture based on jitter_value
    jitter_capture_detector u_jitter_detector (
        .clk(main_clk),
        .rst(reset),
        .counter_in(counter_value),
        .jitter_value(jitter_value),
        .capture_bit_out(capture_bit_signal)
    );

    // Random generator submodule: Updates random_out based on capture_bit
    random_generator u_random_generator (
        .clk(main_clk),
        .rst(reset),
        .capture_bit(capture_bit_signal),
        .counter_lsb(counter_value[0]),
        .random_out(random_out_internal)
    );

    assign random_out = random_out_internal;

endmodule

// -------------------------------------------------------------
// Counter submodule
// Function: 8-bit free-running counter with synchronous reset
// -------------------------------------------------------------
module counter_unit (
    input wire clk,
    input wire rst,
    output reg [7:0] counter_out
);
    wire [7:0] next_counter_value;

    // 8-bit parallel prefix adder for increment operation
    parallel_prefix_adder_8bit u_counter_adder (
        .a(counter_out),
        .b(8'b00000001),
        .sum(next_counter_value)
    );

    always @(posedge clk) begin
        if (rst)
            counter_out <= 8'h01;
        else
            counter_out <= next_counter_value;
    end
endmodule

// -------------------------------------------------------------
// Jitter capture detector submodule
// Function: Toggles capture_bit_out when counter_in equals jitter_value
// -------------------------------------------------------------
module jitter_capture_detector (
    input wire clk,
    input wire rst,
    input wire [7:0] counter_in,
    input wire [7:0] jitter_value,
    output reg capture_bit_out
);
    always @(posedge clk) begin
        if (rst)
            capture_bit_out <= 1'b0;
        else if (counter_in == jitter_value)
            capture_bit_out <= ~capture_bit_out;
    end
endmodule

// -------------------------------------------------------------
// Random generator submodule
// Function: Shifts and updates 16-bit random_out on capture_bit event
// -------------------------------------------------------------
module random_generator (
    input wire clk,
    input wire rst,
    input wire capture_bit,
    input wire counter_lsb,
    output reg [15:0] random_out
);
    wire [15:0] feedback_value;
    wire [15:0] shifted_value;
    wire [15:0] next_random_value;

    assign shifted_value = {random_out[14:0], counter_lsb ^ random_out[15]};

    // 16-bit parallel prefix adder for randomized update (example: add shifted_value and random_out)
    parallel_prefix_adder_16bit u_random_adder (
        .a(shifted_value),
        .b(random_out),
        .sum(feedback_value)
    );

    assign next_random_value = feedback_value;

    always @(posedge clk) begin
        if (rst)
            random_out <= 16'h1234;
        else if (capture_bit)
            random_out <= next_random_value;
    end
endmodule

// -------------------------------------------------------------
// 8-bit Parallel Prefix Adder (Kogge-Stone)
// -------------------------------------------------------------
module parallel_prefix_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum
);
    wire [7:0] g, p;
    wire [7:0] c;

    assign g = a & b;
    assign p = a ^ b;

    // Stage 1
    wire [7:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    genvar i;
    generate
        for (i=1; i<8; i=i+1) begin : stage1
            assign g1[i] = g[i] | (p[i] & g[i-1]);
            assign p1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Stage 2
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign p2[0] = p1[0];
    assign p2[1] = p1[1];
    generate
        for (i=2; i<8; i=i+1) begin : stage2
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] g3, p3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign p3[0] = p2[0];
    assign p3[1] = p2[1];
    assign p3[2] = p2[2];
    assign p3[3] = p2[3];
    generate
        for (i=4; i<8; i=i+1) begin : stage3
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate

    // Carry calculation
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g1[1];
    assign c[3] = g2[2];
    assign c[4] = g3[3];
    assign c[5] = g3[4];
    assign c[6] = g3[5];
    assign c[7] = g3[6];

    // Sum
    assign sum = p ^ c;
endmodule

// -------------------------------------------------------------
// 16-bit Parallel Prefix Adder (Kogge-Stone)
// -------------------------------------------------------------
module parallel_prefix_adder_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [15:0] sum
);
    wire [15:0] g, p;
    wire [15:0] c;

    assign g = a & b;
    assign p = a ^ b;

    // Stage 1
    wire [15:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    genvar i;
    generate
        for (i=1; i<16; i=i+1) begin : stage1
            assign g1[i] = g[i] | (p[i] & g[i-1]);
            assign p1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Stage 2
    wire [15:0] g2, p2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign p2[0] = p1[0];
    assign p2[1] = p1[1];
    generate
        for (i=2; i<16; i=i+1) begin : stage2
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate

    // Stage 3
    wire [15:0] g3, p3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign p3[0] = p2[0];
    assign p3[1] = p2[1];
    assign p3[2] = p2[2];
    assign p3[3] = p2[3];
    generate
        for (i=4; i<16; i=i+1) begin : stage3
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate

    // Stage 4
    wire [15:0] g4, p4;
    assign g4[0] = g3[0];
    assign g4[1] = g3[1];
    assign g4[2] = g3[2];
    assign g4[3] = g3[3];
    assign g4[4] = g3[4];
    assign g4[5] = g3[5];
    assign g4[6] = g3[6];
    assign g4[7] = g3[7];
    assign p4[0] = p3[0];
    assign p4[1] = p3[1];
    assign p4[2] = p3[2];
    assign p4[3] = p3[3];
    assign p4[4] = p3[4];
    assign p4[5] = p3[5];
    assign p4[6] = p3[6];
    assign p4[7] = p3[7];
    generate
        for (i=8; i<16; i=i+1) begin : stage4
            assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
            assign p4[i] = p3[i] & p3[i-8];
        end
    endgenerate

    // Carry calculation
    assign c[0]  = 1'b0;
    assign c[1]  = g[0];
    assign c[2]  = g1[1];
    assign c[3]  = g2[2];
    assign c[4]  = g3[3];
    assign c[5]  = g4[4];
    assign c[6]  = g4[5];
    assign c[7]  = g4[6];
    assign c[8]  = g4[7];
    assign c[9]  = g4[8];
    assign c[10] = g4[9];
    assign c[11] = g4[10];
    assign c[12] = g4[11];
    assign c[13] = g4[12];
    assign c[14] = g4[13];
    assign c[15] = g4[14];

    // Sum
    assign sum = p ^ c;
endmodule