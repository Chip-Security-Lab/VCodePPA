//SystemVerilog
module bit_shuffler #(
    parameter WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      data_in,
    input  wire [1:0]            shuffle_mode,
    output reg  [WIDTH-1:0]      data_out
);

    // Stage 1: Input Latching
    reg [WIDTH-1:0]              data_in_stage1;
    reg [1:0]                    shuffle_mode_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1      <= {WIDTH{1'b0}};
            shuffle_mode_stage1 <= 2'b00;
        end else begin
            data_in_stage1      <= data_in;
            shuffle_mode_stage1 <= shuffle_mode;
        end
    end

    // Stage 2: Shuffle/Operation Preparation
    reg [5:0]                    minuend_stage2;
    reg [5:0]                    subtrahend_stage2;
    reg [5:0]                    shuffle_swap_stage2;
    reg [5:0]                    shuffle_rotate2_stage2;
    reg [5:0]                    shuffle_identity_stage2;
    reg [1:0]                    shuffle_mode_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            minuend_stage2            <= 6'b0;
            subtrahend_stage2         <= 6'b0;
            shuffle_swap_stage2       <= 6'b0;
            shuffle_rotate2_stage2    <= 6'b0;
            shuffle_identity_stage2   <= 6'b0;
            shuffle_mode_stage2       <= 2'b00;
        end else begin
            minuend_stage2            <= data_in_stage1[5:0];
            subtrahend_stage2         <= data_in_stage1[7:2];
            shuffle_swap_stage2       <= {data_in_stage1[3:0], data_in_stage1[7:6]};
            shuffle_rotate2_stage2    <= {data_in_stage1[1:0], data_in_stage1[7:4]};
            shuffle_identity_stage2   <= data_in_stage1[5:0];
            shuffle_mode_stage2       <= shuffle_mode_stage1;
        end
    end

    // Stage 3: Parallel Prefix Subtractor
    wire [5:0]                   diff_result_stage3;
    parallel_prefix_subtractor_6bit u_pps6 (
        .clk        (clk),
        .rst_n      (rst_n),
        .a          (minuend_stage2),
        .b          (subtrahend_stage2),
        .diff       (diff_result_stage3)
    );

    // Stage 4: Output Selection
    reg [WIDTH-1:0]              data_out_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage4 <= {WIDTH{1'b0}};
        end else begin
            case (shuffle_mode_stage2)
                2'b00: data_out_stage4 <= {2'b00, shuffle_identity_stage2};
                2'b01: data_out_stage4 <= {2'b00, shuffle_swap_stage2};
                2'b10: data_out_stage4 <= {2'b00, shuffle_rotate2_stage2};
                2'b11: data_out_stage4 <= {2'b00, diff_result_stage3};
                default: data_out_stage4 <= {WIDTH{1'b0}};
            endcase
        end
    end

    // Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_out_stage4;
        end
    end

endmodule

module parallel_prefix_subtractor_6bit (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [5:0]   a,
    input  wire [5:0]   b,
    output reg  [5:0]   diff
);
    // Pipeline stage 1: Input Latching and Inversion
    reg [5:0]           a_stage1, b_stage1, b_inv_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1     <= 6'b0;
            b_stage1     <= 6'b0;
            b_inv_stage1 <= 6'b0;
        end else begin
            a_stage1     <= a;
            b_stage1     <= b;
            b_inv_stage1 <= ~b;
        end
    end

    // Pipeline stage 2: Generate and Propagate
    reg [5:0]           g_stage2, p_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage2 <= 6'b0;
            p_stage2 <= 6'b0;
        end else begin
            g_stage2[0] <= a_stage1[0] & b_inv_stage1[0];
            p_stage2[0] <= a_stage1[0] ^ b_inv_stage1[0];
            g_stage2[1] <= a_stage1[1] & b_inv_stage1[1];
            p_stage2[1] <= a_stage1[1] ^ b_inv_stage1[1];
            g_stage2[2] <= a_stage1[2] & b_inv_stage1[2];
            p_stage2[2] <= a_stage1[2] ^ b_inv_stage1[2];
            g_stage2[3] <= a_stage1[3] & b_inv_stage1[3];
            p_stage2[3] <= a_stage1[3] ^ b_inv_stage1[3];
            g_stage2[4] <= a_stage1[4] & b_inv_stage1[4];
            p_stage2[4] <= a_stage1[4] ^ b_inv_stage1[4];
            g_stage2[5] <= a_stage1[5] & b_inv_stage1[5];
            p_stage2[5] <= a_stage1[5] ^ b_inv_stage1[5];
        end
    end

    // Pipeline stage 3: Prefix Computation (Kogge-Stone style)
    reg [5:0]           g1_stage3, p1_stage3;
    reg [5:0]           g2_stage3, p2_stage3;
    reg [5:0]           g3_stage3, p2_stage3_hold;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g1_stage3 <= 6'b0; p1_stage3 <= 6'b0;
            g2_stage3 <= 6'b0; p2_stage3 <= 6'b0;
            g3_stage3 <= 6'b0; p2_stage3_hold <= 6'b0;
        end else begin
            // Stage 1
            g1_stage3[0] <= g_stage2[0];
            p1_stage3[0] <= p_stage2[0];
            g1_stage3[1] <= g_stage2[1] | (p_stage2[1] & g_stage2[0]);
            p1_stage3[1] <= p_stage2[1] & p_stage2[0];
            g1_stage3[2] <= g_stage2[2] | (p_stage2[2] & g_stage2[1]);
            p1_stage3[2] <= p_stage2[2] & p_stage2[1];
            g1_stage3[3] <= g_stage2[3] | (p_stage2[3] & g_stage2[2]);
            p1_stage3[3] <= p_stage2[3] & p_stage2[2];
            g1_stage3[4] <= g_stage2[4] | (p_stage2[4] & g_stage2[3]);
            p1_stage3[4] <= p_stage2[4] & p_stage2[3];
            g1_stage3[5] <= g_stage2[5] | (p_stage2[5] & g_stage2[4]);
            p1_stage3[5] <= p_stage2[5] & p_stage2[4];

            // Stage 2
            g2_stage3[0] <= g1_stage3[0];
            p2_stage3[0] <= p1_stage3[0];
            g2_stage3[1] <= g1_stage3[1];
            p2_stage3[1] <= p1_stage3[1];
            g2_stage3[2] <= g1_stage3[2] | (p1_stage3[2] & g1_stage3[0]);
            p2_stage3[2] <= p1_stage3[2] & p1_stage3[0];
            g2_stage3[3] <= g1_stage3[3] | (p1_stage3[3] & g1_stage3[1]);
            p2_stage3[3] <= p1_stage3[3] & p1_stage3[1];
            g2_stage3[4] <= g1_stage3[4] | (p1_stage3[4] & g1_stage3[2]);
            p2_stage3[4] <= p1_stage3[4] & p1_stage3[2];
            g2_stage3[5] <= g1_stage3[5] | (p1_stage3[5] & g1_stage3[3]);
            p2_stage3[5] <= p1_stage3[5] & p1_stage3[3];

            // Stage 3
            g3_stage3[0] <= g2_stage3[0];
            g3_stage3[1] <= g2_stage3[1];
            g3_stage3[2] <= g2_stage3[2];
            g3_stage3[3] <= g2_stage3[3] | (p2_stage3[3] & g2_stage3[0]);
            g3_stage3[4] <= g2_stage3[4] | (p2_stage3[4] & g2_stage3[1]);
            g3_stage3[5] <= g2_stage3[5] | (p2_stage3[5] & g2_stage3[2]);
            p2_stage3_hold <= p2_stage3;
        end
    end

    // Pipeline stage 4: Carry Computation and Output
    reg [6:0]           carry_stage4;
    reg [5:0]           p_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage4 <= 7'b0;
            p_stage4     <= 6'b0;
            diff         <= 6'b0;
        end else begin
            carry_stage4[0] <= 1'b1; // Subtraction: initial carry-in is 1 for two's complement
            carry_stage4[1] <= 1'b1;
            carry_stage4[2] <= g1_stage3[0] | (p1_stage3[0] & 1'b1);
            carry_stage4[3] <= g2_stage3[1] | (p2_stage3[1] & carry_stage4[1]);
            carry_stage4[4] <= g3_stage3[2] | (p2_stage3_hold[2] & carry_stage4[2]);
            carry_stage4[5] <= g3_stage3[3] | (p2_stage3_hold[3] & carry_stage4[3]);
            carry_stage4[6] <= g3_stage3[4] | (p2_stage3_hold[4] & carry_stage4[4]);
            p_stage4        <= p_stage2;

            diff[0] <= p_stage4[0] ^ carry_stage4[0];
            diff[1] <= p_stage4[1] ^ carry_stage4[1];
            diff[2] <= p_stage4[2] ^ carry_stage4[2];
            diff[3] <= p_stage4[3] ^ carry_stage4[3];
            diff[4] <= p_stage4[4] ^ carry_stage4[4];
            diff[5] <= p_stage4[5] ^ carry_stage4[5];
        end
    end

endmodule