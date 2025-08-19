//SystemVerilog
module run_length_encoder (
    input wire clk,
    input wire rst_n,
    input wire data_valid,
    input wire data_in,
    output reg [7:0] count_out,
    output reg data_bit_out,
    output reg valid_out
);

    reg data_prev;
    reg [7:0] counter;

    wire [7:0] counter_next;
    wire carry_out;

    // 8-bit Han-Carlson Adder for counter increment
    han_carlson_adder_8bit han_carlson_adder_inst (
        .a(counter),
        .b(8'b00000001),
        .cin(1'b0),
        .sum(counter_next),
        .cout(carry_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'h1;
            data_prev <= 1'b0;
            valid_out <= 1'b0;
        end else if (data_valid) begin
            if (counter == 8'hFF || data_in != data_prev) begin
                count_out <= counter;
                data_bit_out <= data_prev;
                valid_out <= 1'b1;
                counter <= 8'h1;
            end else begin
                counter <= counter_next;
                valid_out <= 1'b0;
            end
            data_prev <= data_in;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule

module han_carlson_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    // Han-Carlson adder for 8 bits
    wire [7:0] g_lvl0, p_lvl0;       // Level 0 generate/propagate
    wire [7:0] g_lvl1, p_lvl1;       // Level 1
    wire [7:0] g_lvl2, p_lvl2;       // Level 2
    wire [7:0] g_lvl3, p_lvl3;       // Level 3
    wire [7:0] g_lvl4, p_lvl4;       // Level 4 (final)
    wire [8:0] carry;                // Carry chain

    // Initial generate and propagate
    assign g_lvl0 = a & b;
    assign p_lvl0 = a ^ b;

    // Level 1: distance 1
    assign g_lvl1[0] = g_lvl0[0];
    assign p_lvl1[0] = p_lvl0[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : han_level1
            assign g_lvl1[i1] = g_lvl0[i1] | (p_lvl0[i1] & g_lvl0[i1-1]);
            assign p_lvl1[i1] = p_lvl0[i1] & p_lvl0[i1-1];
        end
    endgenerate

    // Level 2: distance 2
    assign g_lvl2[0] = g_lvl1[0];
    assign p_lvl2[0] = p_lvl1[0];
    assign g_lvl2[1] = g_lvl1[1];
    assign p_lvl2[1] = p_lvl1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : han_level2
            assign g_lvl2[i2] = g_lvl1[i2] | (p_lvl1[i2] & g_lvl1[i2-2]);
            assign p_lvl2[i2] = p_lvl1[i2] & p_lvl1[i2-2];
        end
    endgenerate

    // Level 3: distance 4
    assign g_lvl3[0] = g_lvl2[0];
    assign p_lvl3[0] = p_lvl2[0];
    assign g_lvl3[1] = g_lvl2[1];
    assign p_lvl3[1] = p_lvl2[1];
    assign g_lvl3[2] = g_lvl2[2];
    assign p_lvl3[2] = p_lvl2[2];
    assign g_lvl3[3] = g_lvl2[3];
    assign p_lvl3[3] = p_lvl2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : han_level3
            assign g_lvl3[i3] = g_lvl2[i3] | (p_lvl2[i3] & g_lvl2[i3-4]);
            assign p_lvl3[i3] = p_lvl2[i3] & p_lvl2[i3-4];
        end
    endgenerate

    // Level 4: Suffix stage (reverse tree, Han-Carlson)
    assign g_lvl4[0] = g_lvl0[0];
    assign p_lvl4[0] = p_lvl0[0];

    assign g_lvl4[1] = g_lvl1[1];
    assign p_lvl4[1] = p_lvl1[1];

    assign g_lvl4[2] = g_lvl2[2];
    assign p_lvl4[2] = p_lvl2[2];

    assign g_lvl4[3] = g_lvl2[3];
    assign p_lvl4[3] = p_lvl2[3];

    assign g_lvl4[4] = g_lvl3[4];
    assign p_lvl4[4] = p_lvl3[4];

    assign g_lvl4[5] = g_lvl3[5];
    assign p_lvl4[5] = p_lvl3[5];

    assign g_lvl4[6] = g_lvl3[6];
    assign p_lvl4[6] = p_lvl3[6];

    assign g_lvl4[7] = g_lvl3[7];
    assign p_lvl4[7] = p_lvl3[7];

    // Carry generation
    assign carry[0] = cin;
    assign carry[1] = g_lvl4[0] | (p_lvl4[0] & carry[0]);
    assign carry[2] = g_lvl4[1] | (p_lvl4[1] & carry[1]);
    assign carry[3] = g_lvl4[2] | (p_lvl4[2] & carry[2]);
    assign carry[4] = g_lvl4[3] | (p_lvl4[3] & carry[3]);
    assign carry[5] = g_lvl4[4] | (p_lvl4[4] & carry[4]);
    assign carry[6] = g_lvl4[5] | (p_lvl4[5] & carry[5]);
    assign carry[7] = g_lvl4[6] | (p_lvl4[6] & carry[6]);
    assign carry[8] = g_lvl4[7] | (p_lvl4[7] & carry[7]);

    assign sum = p_lvl0 ^ carry[7:0];
    assign cout = carry[8];

endmodule