//SystemVerilog
module ring_osc_rng (
    input wire system_clk,
    input wire reset_n,
    output reg [7:0] random_byte
);

    // Oscillator counters and outputs
    reg [3:0] osc_counter_0;
    reg [3:0] osc_counter_1;
    reg [3:0] osc_counter_2;
    reg [3:0] osc_counter_3;

    wire [3:0] osc_bits;

    // Oscillator counter update: osc_counter_0
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            osc_counter_0 <= 4'd1;
        else
            osc_counter_0 <= kogge_stone_adder_4b(osc_counter_0, 4'd1, 1'b0);
    end

    // Oscillator counter update: osc_counter_1
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            osc_counter_1 <= 4'd2;
        else
            osc_counter_1 <= kogge_stone_adder_4b(osc_counter_1, 4'd2, 1'b0);
    end

    // Oscillator counter update: osc_counter_2
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            osc_counter_2 <= 4'd3;
        else
            osc_counter_2 <= kogge_stone_adder_4b(osc_counter_2, 4'd3, 1'b0);
    end

    // Oscillator counter update: osc_counter_3
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            osc_counter_3 <= 4'd4;
        else
            osc_counter_3 <= kogge_stone_adder_4b(osc_counter_3, 4'd4, 1'b0);
    end

    // Derive oscillator outputs
    assign osc_bits[0] = osc_counter_0[3];
    assign osc_bits[1] = osc_counter_1[3];
    assign osc_bits[2] = osc_counter_2[3];
    assign osc_bits[3] = osc_counter_3[3];

    // Collect random bits
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            random_byte <= 8'h42;
        else
            random_byte <= kogge_stone_adder_8b({random_byte[3:0], osc_bits}, 8'b0, 1'b0);
    end

    // Kogge-Stone Adder 4-bit function
    function [3:0] kogge_stone_adder_4b;
        input [3:0] a;
        input [3:0] b;
        input       cin;
        reg [3:0] p, g;
        reg [3:0] c;
        begin
            p = a ^ b;
            g = a & b;

            c[0] = cin;
            c[1] = g[0] | (p[0] & cin);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);

            kogge_stone_adder_4b = p ^ c;
        end
    endfunction

    // Kogge-Stone Adder 8-bit function
    function [7:0] kogge_stone_adder_8b;
        input [7:0] a;
        input [7:0] b;
        input       cin;
        reg [7:0] p, g;
        reg [7:0] c;
        begin
            p = a ^ b;
            g = a & b;

            c[0] = cin;
            c[1] = g[0] | (p[0] & cin);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
            c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
            c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & cin);
            c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
            c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);

            kogge_stone_adder_8b = p ^ c;
        end
    endfunction

endmodule