//SystemVerilog
module thermometer_to_binary #(
    parameter THERMO_WIDTH = 7
)(
    input  wire [THERMO_WIDTH-1:0] thermo_in,
    output reg  [$clog2(THERMO_WIDTH+1)-1:0] binary_out
);

    // Stage 1: Input Register
    reg [THERMO_WIDTH-1:0] stage1_thermo_in;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_thermo_in <= {THERMO_WIDTH{1'b0}};
        else
            stage1_thermo_in <= thermo_in;
    end

    // Stage 2: Brent-Kung Adder Pipeline
    wire [2:0] stage2_sum;
    brent_kung_adder_7bit_pipelined u_bk_adder (
        .clk(clk),
        .rst_n(rst_n),
        .a(stage1_thermo_in),
        .b(7'b0),
        .sum(stage2_sum)
    );

    // Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_out <= {($clog2(THERMO_WIDTH+1)){1'b0}};
        else
            binary_out <= stage2_sum;
    end

endmodule

module brent_kung_adder_7bit_pipelined (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [6:0]  a,
    input  wire [6:0]  b,
    output reg  [2:0]  sum
);

    // ----------- Stage 1: Generate and Propagate -----------
    reg [6:0] g_stage1, p_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage1 <= 7'b0;
            p_stage1 <= 7'b0;
        end else begin
            g_stage1 <= a & b;
            p_stage1 <= a ^ b;
        end
    end

    // ----------- Stage 2: Level 2 Brent-Kung -----------
    reg [6:0] g_stage2, p_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage2 <= 7'b0;
            p_stage2 <= 7'b0;
        end else begin
            g_stage2[0] <= g_stage1[0];
            p_stage2[0] <= p_stage1[0];
            g_stage2[1] <= g_stage1[1] | (p_stage1[1] & g_stage1[0]);
            p_stage2[1] <= p_stage1[1] & p_stage1[0];
            g_stage2[2] <= g_stage1[2];
            p_stage2[2] <= p_stage1[2];
            g_stage2[3] <= g_stage1[3] | (p_stage1[3] & g_stage1[2]);
            p_stage2[3] <= p_stage1[3] & p_stage1[2];
            g_stage2[4] <= g_stage1[4];
            p_stage2[4] <= p_stage1[4];
            g_stage2[5] <= g_stage1[5] | (p_stage1[5] & g_stage1[4]);
            p_stage2[5] <= p_stage1[5] & p_stage1[4];
            g_stage2[6] <= g_stage1[6];
            p_stage2[6] <= p_stage1[6];
        end
    end

    // ----------- Stage 3: Level 3 Brent-Kung -----------
    reg [6:0] g_stage3, p_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage3 <= 7'b0;
            p_stage3 <= 7'b0;
        end else begin
            g_stage3[0] <= g_stage2[0];
            g_stage3[1] <= g_stage2[1];
            g_stage3[2] <= g_stage2[2] | (p_stage2[2] & g_stage2[0]);
            g_stage3[3] <= g_stage2[3];
            g_stage3[4] <= g_stage2[4] | (p_stage2[4] & g_stage2[2]);
            g_stage3[5] <= g_stage2[5];
            g_stage3[6] <= g_stage2[6] | (p_stage2[6] & g_stage2[4]);
            p_stage3    <= p_stage2;
        end
    end

    // ----------- Stage 4: Carry Generation & Sum -----------
    reg [7:0] carry_stage4;
    reg [6:0] sum_internal_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage4        <= 8'b0;
            sum_internal_stage4 <= 7'b0;
        end else begin
            carry_stage4[0] <= 1'b0;
            carry_stage4[1] <= g_stage3[0];
            carry_stage4[2] <= g_stage3[1];
            carry_stage4[3] <= g_stage3[2];
            carry_stage4[4] <= g_stage3[3];
            carry_stage4[5] <= g_stage3[4];
            carry_stage4[6] <= g_stage3[5];
            carry_stage4[7] <= g_stage3[6];

            sum_internal_stage4[0] <= p_stage3[0] ^ carry_stage4[0];
            sum_internal_stage4[1] <= p_stage3[1] ^ carry_stage4[1];
            sum_internal_stage4[2] <= p_stage3[2] ^ carry_stage4[2];
            sum_internal_stage4[3] <= p_stage3[3] ^ carry_stage4[3];
            sum_internal_stage4[4] <= p_stage3[4] ^ carry_stage4[4];
            sum_internal_stage4[5] <= p_stage3[5] ^ carry_stage4[5];
            sum_internal_stage4[6] <= p_stage3[6] ^ carry_stage4[6];
        end
    end

    // ----------- Stage 5: Population Count -----------
    reg [2:0] popcount_stage1, popcount_stage2, popcount_stage3, popcount_stage4, sum_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            popcount_stage1 <= 3'b0;
            popcount_stage2 <= 3'b0;
            popcount_stage3 <= 3'b0;
            popcount_stage4 <= 3'b0;
            sum_stage5      <= 3'b0;
            sum             <= 3'b0;
        end else begin
            popcount_stage1 <= sum_internal_stage4[0] + sum_internal_stage4[1];
            popcount_stage2 <= popcount_stage1 + sum_internal_stage4[2];
            popcount_stage3 <= popcount_stage2 + sum_internal_stage4[3];
            popcount_stage4 <= popcount_stage3 + sum_internal_stage4[4];
            sum_stage5      <= popcount_stage4 + sum_internal_stage4[5] + sum_internal_stage4[6];
            sum             <= sum_stage5;
        end
    end

endmodule