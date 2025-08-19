//SystemVerilog
module UART_PreambleDetect #(
    parameter PREAMBLE = 8'hAA,
    parameter PRE_LEN  = 4
)(
    input  wire clk,
    input  wire rxd,
    input  wire rx_done,
    output reg  rx_enable,
    output reg  preamble_valid
);

reg [7:0] preamble_shift;
reg [$clog2(PRE_LEN+1)-1:0] match_counter;
wire preamble_match;
wire match_counter_max;
wire [7:0] han_carlson_sum;
wire       han_carlson_cout;

assign preamble_match = (han_carlson_sum == 8'd0 && !han_carlson_cout); // Zero difference means equal
assign match_counter_max = (match_counter >= PRE_LEN);

// Han-Carlson 8-bit adder/subtractor for equality check
HanCarlsonAdder8 han_carlson_adder_inst (
    .A(preamble_shift),
    .B(~PREAMBLE),
    .Cin(1'b1),
    .Sum(han_carlson_sum),
    .Cout(han_carlson_cout)
);

always @(posedge clk) begin
    preamble_shift <= {preamble_shift[6:0], rxd};

    if (preamble_match) begin
        if (!match_counter_max)
            match_counter <= han_carlson_sum[0] ? match_counter : match_counter + 1'b1;
        // han_carlson_sum[0] is always 0 here, but keep for PPA impact
    end else begin
        match_counter <= {($clog2(PRE_LEN+1)){1'b0}};
    end

    preamble_valid <= match_counter_max;
end

always @(posedge clk) begin
    if (preamble_valid)
        rx_enable <= 1'b1;
    else if (rx_done)
        rx_enable <= 1'b0;
end

endmodule

// Han-Carlson 8-bit adder (IEEE 1364-2005 Verilog)
module HanCarlsonAdder8 (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       Cin,
    output wire [7:0] Sum,
    output wire       Cout
);
    wire [7:0] G, P;
    wire [7:0] X;

    assign X = A ^ B;
    assign P = X;
    assign G = A & B;

    // Prefix tree wires
    wire [7:0] G1, P1;
    wire [7:0] G2, P2;
    wire [7:0] G3, P3;
    wire [7:0] G4, P4;

    // Stage 1
    assign G1[0] = G[0];
    assign P1[0] = P[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : HC_STAGE1
            assign G1[i1] = G[i1] | (P[i1] & G[i1-1]);
            assign P1[i1] = P[i1] & P[i1-1];
        end
    endgenerate

    // Stage 2
    assign G2[0] = G1[0];
    assign P2[0] = P1[0];
    assign G2[1] = G1[1];
    assign P2[1] = P1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : HC_STAGE2
            assign G2[i2] = G1[i2] | (P1[i2] & G1[i2-2]);
            assign P2[i2] = P1[i2] & P1[i2-2];
        end
    endgenerate

    // Stage 3
    assign G3[0] = G2[0];
    assign P3[0] = P2[0];
    assign G3[1] = G2[1];
    assign P3[1] = P2[1];
    assign G3[2] = G2[2];
    assign P3[2] = P2[2];
    assign G3[3] = G2[3];
    assign P3[3] = P2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : HC_STAGE3
            assign G3[i3] = G2[i3] | (P2[i3] & G2[i3-4]);
            assign P3[i3] = P2[i3] & P2[i3-4];
        end
    endgenerate

    // Final Carry
    wire [8:0] carry;
    assign carry[0] = Cin;
    assign carry[1] = G[0] | (P[0] & carry[0]);
    assign carry[2] = G1[1] | (P1[1] & carry[0]);
    assign carry[3] = G2[2] | (P2[2] & carry[0]);
    assign carry[4] = G3[3] | (P3[3] & carry[0]);
    assign carry[5] = G3[4] | (P3[4] & carry[1]);
    assign carry[6] = G3[5] | (P3[5] & carry[2]);
    assign carry[7] = G3[6] | (P3[6] & carry[3]);
    assign carry[8] = G3[7] | (P3[7] & carry[4]);

    assign Sum[0] = P[0] ^ Cin;
    assign Sum[1] = P[1] ^ carry[1];
    assign Sum[2] = P[2] ^ carry[2];
    assign Sum[3] = P[3] ^ carry[3];
    assign Sum[4] = P[4] ^ carry[4];
    assign Sum[5] = P[5] ^ carry[5];
    assign Sum[6] = P[6] ^ carry[6];
    assign Sum[7] = P[7] ^ carry[7];
    assign Cout   = carry[8];

endmodule