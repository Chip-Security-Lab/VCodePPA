//SystemVerilog
module duty_cycle_controller(
    input wire clock_in,
    input wire reset,
    input wire [3:0] duty_cycle, // 0-15 (0%-93.75%)
    output reg clock_out
);

    // Stage 1: Counter increment
    reg [3:0] count_stage1;
    reg [3:0] count_stage2;
    reg [3:0] count_stage3;

    // Stage 2: Duty cycle comparison
    reg [3:0] duty_cycle_stage2;
    reg [3:0] duty_cycle_stage3;
    reg duty_compare_stage2;
    reg duty_compare_stage3;

    // Stage 3: Output register
    reg clock_out_stage3;

    // Internal wire for next counter value
    wire [3:0] next_count_stage1;

    // Kogge-Stone Adder instance for count increment
    kogge_stone_adder_4bit u_kogge_stone_adder_4bit (
        .a(count_stage1),
        .b(4'b0001),
        .cin(1'b0),
        .sum(next_count_stage1),
        .cout()
    );

    // Stage 1: Counter logic with Kogge-Stone adder
    always @(posedge clock_in) begin
        if (reset) begin
            count_stage1 <= 4'd0;
            duty_cycle_stage2 <= 4'd0;
        end else begin
            if (count_stage1 < 4'd15)
                count_stage1 <= next_count_stage1;
            else
                count_stage1 <= 4'd0;

            // Register duty_cycle for next stage
            duty_cycle_stage2 <= duty_cycle;
        end
    end

    // Stage 2: Comparison logic
    always @(posedge clock_in) begin
        if (reset) begin
            count_stage2 <= 4'd0;
            duty_cycle_stage3 <= 4'd0;
            duty_compare_stage2 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            duty_cycle_stage3 <= duty_cycle_stage2;
            duty_compare_stage2 <= (count_stage1 < duty_cycle_stage2) ? 1'b1 : 1'b0;
        end
    end

    // Stage 3: Output register logic
    always @(posedge clock_in) begin
        if (reset) begin
            count_stage3 <= 4'd0;
            duty_compare_stage3 <= 1'b0;
            clock_out_stage3 <= 1'b0;
        end else begin
            count_stage3 <= count_stage2;
            duty_compare_stage3 <= duty_compare_stage2;
            clock_out_stage3 <= duty_compare_stage2;
        end
    end

    // Output assignment
    always @(posedge clock_in) begin
        if (reset) begin
            clock_out <= 1'b0;
        end else begin
            clock_out <= clock_out_stage3;
        end
    end

endmodule

module kogge_stone_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    // Generate and Propagate
    wire [3:0] g, p;
    assign g = a & b;
    assign p = a ^ b;

    // Stage 1
    wire [3:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];

    // Stage 2
    wire [3:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];

    // Carry
    wire [4:0] carry;
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g1[1] | (p1[1] & carry[0]);
    assign carry[3] = g2[2] | (p2[2] & carry[0]);
    assign carry[4] = g2[3] | (p2[3] & carry[0]);

    // Sum
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];

    assign cout = carry[4];

endmodule