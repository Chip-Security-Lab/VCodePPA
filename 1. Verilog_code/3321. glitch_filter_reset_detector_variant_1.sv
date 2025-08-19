//SystemVerilog
module glitch_filter_reset_detector(
    input clk,
    input rst_n,
    input raw_reset,
    output reg filtered_reset
);

    // Stage 1: Shift Register
    reg [7:0] shift_reg_stage1;
    reg [7:0] shift_reg_stage2;

    // Stage 2: Partial Count Ones (split into two 4-bit counts)
    reg [2:0] ones_count_lower_stage2;
    reg [2:0] ones_count_upper_stage2;
    reg [3:0] ones_count_total_stage3;

    // Stage 3: Reset Detection
    reg reset_detected_stage3;
    reg reset_detected_stage4;

    // Stage 4: Hysteresis Control
    reg filtered_reset_stage4;

    // Partial count function for 4 bits
    function [2:0] count_ones_4b;
        input [3:0] data;
        begin
            count_ones_4b = data[0] + data[1] + data[2] + data[3];
        end
    endfunction

    // Brent-Kung 8-bit Adder for summing ones_count_lower_stage2 and ones_count_upper_stage2
    wire [2:0] adder_in_a;
    wire [2:0] adder_in_b;
    wire [3:0] adder_sum;

    assign adder_in_a = ones_count_lower_stage2;
    assign adder_in_b = ones_count_upper_stage2;

    brent_kung_adder_3b u_bk_adder (
        .a(adder_in_a),
        .b(adder_in_b),
        .sum(adder_sum)
    );

    // Stage 1: Shift Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 8'h00;
        end else begin
            shift_reg_stage1 <= {shift_reg_stage1[6:0], raw_reset};
        end
    end

    // Stage 2: Register shift_reg and count ones in lower and upper 4 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'h00;
            ones_count_lower_stage2 <= 3'd0;
            ones_count_upper_stage2 <= 3'd0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            ones_count_lower_stage2 <= count_ones_4b(shift_reg_stage1[3:0]);
            ones_count_upper_stage2 <= count_ones_4b(shift_reg_stage1[7:4]);
        end
    end

    // Stage 3: Sum the two partial counts (using Brent-Kung adder) and detect reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ones_count_total_stage3 <= 4'd0;
            reset_detected_stage3 <= 1'b0;
        end else begin
            ones_count_total_stage3 <= adder_sum;
            reset_detected_stage3 <= (adder_sum >= 4'd5);
        end
    end

    // Stage 4: Register reset_detected and filtered_reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_stage4 <= 1'b0;
            filtered_reset_stage4 <= 1'b0;
        end else begin
            reset_detected_stage4 <= reset_detected_stage3;
            // Hysteresis logic
            if (reset_detected_stage3 && filtered_reset_stage4)
                filtered_reset_stage4 <= 1'b1;
            else if (reset_detected_stage3 && !filtered_reset_stage4)
                filtered_reset_stage4 <= 1'b1;
            else if (!reset_detected_stage3 && filtered_reset_stage4)
                filtered_reset_stage4 <= shift_reg_stage2[7:6] != 2'b00;
            else
                filtered_reset_stage4 <= 1'b0;
        end
    end

    // Stage 5: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_reset <= 1'b0;
        end else begin
            filtered_reset <= filtered_reset_stage4;
        end
    end

endmodule

// Brent-Kung 3-bit Adder (outputs 4-bit sum)
module brent_kung_adder_3b(
    input  [2:0] a,
    input  [2:0] b,
    output [3:0] sum
);
    wire [2:0] p, g;
    wire [2:0] c;

    // Propagate and generate
    assign p = a ^ b;
    assign g = a & b;

    // Carry computation (Brent-Kung structure for 3 bits)
    // Level 1
    wire g1_0, p1_0;
    assign g1_0 = g[1] | (p[1] & g[0]);
    assign p1_0 = p[1] & p[0];

    // Level 2
    wire g2_0;
    assign g2_0 = g[2] | (p[2] & g1_0);

    // Carry chain
    assign c[0] = g[0];
    assign c[1] = g1_0;
    assign c[2] = g2_0;

    // Sum bits
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ c[0];
    assign sum[2] = p[2] ^ c[1];
    assign sum[3] = c[2];

endmodule