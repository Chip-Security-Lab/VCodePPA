//SystemVerilog
module watchdog_reset_detector #(
    parameter TIMEOUT = 16'hFFFF
)(
    input clk,
    input enable,
    input watchdog_kick,
    input ext_reset_n,
    input pwr_reset_n,
    output reg system_reset,
    output reg [1:0] reset_source
);

    // Watchdog counter register
    reg [15:0] watchdog_counter = 16'h0000;

    // Asynchronous reset signals (active high)
    wire ext_reset_active = ~ext_reset_n;
    wire pwr_reset_active = ~pwr_reset_n;

    // Watchdog timeout condition
    wire watchdog_timeout = (watchdog_counter >= TIMEOUT);

    // 16-bit Kogge-Stone Adder instance
    wire [15:0] adder_a;
    wire [15:0] adder_b;
    wire        adder_cin;
    wire [15:0] adder_sum;
    wire        adder_cout;

    assign adder_a   = watchdog_counter;
    assign adder_b   = 16'h0001;
    assign adder_cin = 1'b0;

    kogge_stone_adder_16bit u_kogge_stone_adder_16bit (
        .a    (adder_a),
        .b    (adder_b),
        .cin  (adder_cin),
        .sum  (adder_sum),
        .cout (adder_cout)
    );

    //==========================================================
    // Combined Sequential Logic: Watchdog Counter, Reset, and Source
    //==========================================================
    always @(posedge clk) begin
        // Watchdog Counter Control
        if (!enable)
            watchdog_counter <= 16'h0000;
        else if (watchdog_kick)
            watchdog_counter <= 16'h0000;
        else
            watchdog_counter <= adder_sum;

        // System Reset Control
        system_reset <= watchdog_timeout | ext_reset_active | pwr_reset_active;

        // Reset Source Selection
        // Priority: Power-On Reset > External Reset > Watchdog Timeout > No Reset
        if (pwr_reset_active)
            reset_source <= 2'b00;
        else if (ext_reset_active)
            reset_source <= 2'b01;
        else if (watchdog_timeout)
            reset_source <= 2'b10;
        else
            reset_source <= 2'b11;
    end

endmodule

module kogge_stone_adder_16bit(
    input  [15:0] a,
    input  [15:0] b,
    input         cin,
    output [15:0] sum,
    output        cout
);
    wire [15:0] p, g;
    wire [15:0] c;

    assign p = a ^ b;
    assign g = a & b;

    // Stage 0
    wire [15:0] gnpg_0, pp_0;
    assign gnpg_0 = g;
    assign pp_0   = p;

    // Stage 1
    wire [15:0] gnpg_1, pp_1;
    assign gnpg_1[0]  = gnpg_0[0];
    assign pp_1[0]    = pp_0[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 16; i1 = i1 + 1) begin : stage1
            assign gnpg_1[i1] = gnpg_0[i1] | (pp_0[i1] & gnpg_0[i1-1]);
            assign pp_1[i1]   = pp_0[i1] & pp_0[i1-1];
        end
    endgenerate

    // Stage 2
    wire [15:0] gnpg_2, pp_2;
    assign gnpg_2[0]  = gnpg_1[0];
    assign gnpg_2[1]  = gnpg_1[1];
    assign pp_2[0]    = pp_1[0];
    assign pp_2[1]    = pp_1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 16; i2 = i2 + 1) begin : stage2
            assign gnpg_2[i2] = gnpg_1[i2] | (pp_1[i2] & gnpg_1[i2-2]);
            assign pp_2[i2]   = pp_1[i2] & pp_1[i2-2];
        end
    endgenerate

    // Stage 3
    wire [15:0] gnpg_3, pp_3;
    assign gnpg_3[0]  = gnpg_2[0];
    assign gnpg_3[1]  = gnpg_2[1];
    assign gnpg_3[2]  = gnpg_2[2];
    assign gnpg_3[3]  = gnpg_2[3];
    assign pp_3[0]    = pp_2[0];
    assign pp_3[1]    = pp_2[1];
    assign pp_3[2]    = pp_2[2];
    assign pp_3[3]    = pp_2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 16; i3 = i3 + 1) begin : stage3
            assign gnpg_3[i3] = gnpg_2[i3] | (pp_2[i3] & gnpg_2[i3-4]);
            assign pp_3[i3]   = pp_2[i3] & pp_2[i3-4];
        end
    endgenerate

    // Stage 4
    wire [15:0] gnpg_4;
    assign gnpg_4[0]  = gnpg_3[0];
    assign gnpg_4[1]  = gnpg_3[1];
    assign gnpg_4[2]  = gnpg_3[2];
    assign gnpg_4[3]  = gnpg_3[3];
    assign gnpg_4[4]  = gnpg_3[4];
    assign gnpg_4[5]  = gnpg_3[5];
    assign gnpg_4[6]  = gnpg_3[6];
    assign gnpg_4[7]  = gnpg_3[7];
    genvar i4;
    generate
        for (i4 = 8; i4 < 16; i4 = i4 + 1) begin : stage4
            assign gnpg_4[i4] = gnpg_3[i4] | (pp_3[i4] & gnpg_3[i4-8]);
        end
    endgenerate

    // Carry generation
    assign c[0] = cin;
    assign c[1] = gnpg_0[0] | (pp_0[0] & cin);
    assign c[2] = gnpg_1[1] | (pp_1[1] & cin);
    assign c[3] = gnpg_2[2] | (pp_2[2] & cin);
    assign c[4] = gnpg_3[3] | (pp_3[3] & cin);
    assign c[5] = gnpg_4[4] | (pp_3[4] & c[0]);
    assign c[6] = gnpg_4[5] | (pp_3[5] & c[1]);
    assign c[7] = gnpg_4[6] | (pp_3[6] & c[2]);
    assign c[8] = gnpg_4[7] | (pp_3[7] & c[3]);
    assign c[9] = gnpg_4[8] | (pp_3[8] & c[4]);
    assign c[10] = gnpg_4[9] | (pp_3[9] & c[5]);
    assign c[11] = gnpg_4[10] | (pp_3[10] & c[6]);
    assign c[12] = gnpg_4[11] | (pp_3[11] & c[7]);
    assign c[13] = gnpg_4[12] | (pp_3[12] & c[8]);
    assign c[14] = gnpg_4[13] | (pp_3[13] & c[9]);
    assign c[15] = gnpg_4[14] | (pp_3[14] & c[10]);

    assign sum  = p ^ {c[15:0]};
    assign cout = gnpg_4[15] | (pp_3[15] & c[11]);

endmodule