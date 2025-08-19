//SystemVerilog
module log_to_linear #(parameter WIDTH=8, LUT_SIZE=16)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      log_in,
    output reg  [WIDTH-1:0]      linear_out
);

    // LUT ROM
    reg [WIDTH-1:0] lut [0:LUT_SIZE-1];
    integer i;

    // Pipeline registers for dataflow clarity
    reg  [WIDTH-1:0] log_stage1;
    reg  [WIDTH-1:0] log_stage2;

    reg  [WIDTH-1:0] lut_val_stage1;
    reg  [WIDTH-1:0] lut_val_stage2;

    reg  [WIDTH-1:0] add_op_stage1;
    reg  [WIDTH-1:0] add_op_stage2;

    wire [WIDTH-1:0] adder_sum_stage3;

    // LUT Initialization
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut[i] = (1 << (i/2));
        end
    end

    // Stage 1: Input sample pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log_stage1     <= {WIDTH{1'b0}};
        end else begin
            log_stage1     <= log_in;
        end
    end

    // Stage 2: LUT access and operand calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_val_stage1  <= {WIDTH{1'b0}};
            add_op_stage1   <= {WIDTH{1'b0}};
        end else begin
            if (log_stage1 < LUT_SIZE) begin
                lut_val_stage1  <= lut[log_stage1];
                add_op_stage1   <= {WIDTH{1'b0}};
            end else begin
                lut_val_stage1  <= {WIDTH{1'b1}};
                add_op_stage1   <= {WIDTH{1'b0}};
            end
        end
    end

    // Stage 3: Pipeline registers for adder inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_val_stage2  <= {WIDTH{1'b0}};
            add_op_stage2   <= {WIDTH{1'b0}};
        end else begin
            lut_val_stage2  <= lut_val_stage1;
            add_op_stage2   <= add_op_stage1;
        end
    end

    // Stage 4: Han-Carlson Adder
    han_carlson_adder_8bit u_han_carlson_adder (
        .clk(clk),
        .rst_n(rst_n),
        .a(lut_val_stage2),
        .b(add_op_stage2),
        .sum(adder_sum_stage3)
    );

    // Stage 5: Output register for linear_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            linear_out <= {WIDTH{1'b0}};
        end else begin
            linear_out <= adder_sum_stage3;
        end
    end

endmodule

// 8-bit Han-Carlson Adder with pipeline for improved dataflow clarity (IEEE 1364-2005)
module han_carlson_adder_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [7:0]  sum
);

    // Pipeline registers for adder stages
    reg [7:0] a_stage1, b_stage1;
    reg [7:0] g_stage1, p_stage1;
    reg [7:0] g1_stage2, p1_stage2;
    reg [7:0] g2_stage3, p2_stage3;
    reg [7:0] g3_stage4, p3_stage4;
    reg [7:0] c_stage5;
    reg [7:0] p_final_stage5;

    // Stage 1: Compute generate and propagate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            g_stage1 <= 8'b0;
            p_stage1 <= 8'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            g_stage1 <= a & b;
            p_stage1 <= a ^ b;
        end
    end

    // Stage 2: Han-Carlson prefix - Level 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g1_stage2 <= 8'b0;
            p1_stage2 <= 8'b0;
        end else begin
            g1_stage2[0] <= g_stage1[0];
            p1_stage2[0] <= p_stage1[0];
            g1_stage2[1] <= g_stage1[1] | (p_stage1[1] & g_stage1[0]);
            p1_stage2[1] <= p_stage1[1] & p_stage1[0];
            g1_stage2[2] <= g_stage1[2] | (p_stage1[2] & g_stage1[1]);
            p1_stage2[2] <= p_stage1[2] & p_stage1[1];
            g1_stage2[3] <= g_stage1[3] | (p_stage1[3] & g_stage1[2]);
            p1_stage2[3] <= p_stage1[3] & p_stage1[2];
            g1_stage2[4] <= g_stage1[4] | (p_stage1[4] & g_stage1[3]);
            p1_stage2[4] <= p_stage1[4] & p_stage1[3];
            g1_stage2[5] <= g_stage1[5] | (p_stage1[5] & g_stage1[4]);
            p1_stage2[5] <= p_stage1[5] & p_stage1[4];
            g1_stage2[6] <= g_stage1[6] | (p_stage1[6] & g_stage1[5]);
            p1_stage2[6] <= p_stage1[6] & p_stage1[5];
            g1_stage2[7] <= g_stage1[7] | (p_stage1[7] & g_stage1[6]);
            p1_stage2[7] <= p_stage1[7] & p_stage1[6];
        end
    end

    // Stage 3: Han-Carlson prefix - Level 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g2_stage3 <= 8'b0;
            p2_stage3 <= 8'b0;
        end else begin
            g2_stage3[0] <= g1_stage2[0];
            p2_stage3[0] <= p1_stage2[0];
            g2_stage3[1] <= g1_stage2[1];
            p2_stage3[1] <= p1_stage2[1];
            g2_stage3[2] <= g1_stage2[2] | (p1_stage2[2] & g1_stage2[0]);
            p2_stage3[2] <= p1_stage2[2] & p1_stage2[0];
            g2_stage3[3] <= g1_stage2[3] | (p1_stage2[3] & g1_stage2[1]);
            p2_stage3[3] <= p1_stage2[3] & p1_stage2[1];
            g2_stage3[4] <= g1_stage2[4] | (p1_stage2[4] & g1_stage2[2]);
            p2_stage3[4] <= p1_stage2[4] & p1_stage2[2];
            g2_stage3[5] <= g1_stage2[5] | (p1_stage2[5] & g1_stage2[3]);
            p2_stage3[5] <= p1_stage2[5] & p1_stage2[3];
            g2_stage3[6] <= g1_stage2[6] | (p1_stage2[6] & g1_stage2[4]);
            p2_stage3[6] <= p1_stage2[6] & p1_stage2[4];
            g2_stage3[7] <= g1_stage2[7] | (p1_stage2[7] & g1_stage2[5]);
            p2_stage3[7] <= p1_stage2[7] & p1_stage2[5];
        end
    end

    // Stage 4: Han-Carlson prefix - Level 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g3_stage4 <= 8'b0;
            p3_stage4 <= 8'b0;
        end else begin
            g3_stage4[0] <= g2_stage3[0];
            p3_stage4[0] <= p2_stage3[0];
            g3_stage4[1] <= g2_stage3[1];
            p3_stage4[1] <= p2_stage3[1];
            g3_stage4[2] <= g2_stage3[2];
            p3_stage4[2] <= p2_stage3[2];
            g3_stage4[3] <= g2_stage3[3] | (p2_stage3[3] & g2_stage3[0]);
            p3_stage4[3] <= p2_stage3[3] & p2_stage3[0];
            g3_stage4[4] <= g2_stage3[4] | (p2_stage3[4] & g2_stage3[1]);
            p3_stage4[4] <= p2_stage3[4] & p2_stage3[1];
            g3_stage4[5] <= g2_stage3[5] | (p2_stage3[5] & g2_stage3[2]);
            p3_stage4[5] <= p2_stage3[5] & p2_stage3[2];
            g3_stage4[6] <= g2_stage3[6] | (p2_stage3[6] & g2_stage3[3]);
            p3_stage4[6] <= p2_stage3[6] & p2_stage3[3];
            g3_stage4[7] <= g2_stage3[7] | (p2_stage3[7] & g2_stage3[4]);
            p3_stage4[7] <= p2_stage3[7] & p2_stage3[4];
        end
    end

    // Stage 5: Carry calculation and final sum
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_stage5        <= 8'b0;
            p_final_stage5  <= 8'b0;
            sum             <= 8'b0;
        end else begin
            c_stage5[0] <= 1'b0;
            c_stage5[1] <= g_stage1[0];
            c_stage5[2] <= g1_stage2[1];
            c_stage5[3] <= g2_stage3[2];
            c_stage5[4] <= g3_stage4[3];
            c_stage5[5] <= g3_stage4[4];
            c_stage5[6] <= g3_stage4[5];
            c_stage5[7] <= g3_stage4[6];
            p_final_stage5 <= p_stage1;
            sum[0] <= p_final_stage5[0] ^ c_stage5[0];
            sum[1] <= p_final_stage5[1] ^ c_stage5[1];
            sum[2] <= p_final_stage5[2] ^ c_stage5[2];
            sum[3] <= p_final_stage5[3] ^ c_stage5[3];
            sum[4] <= p_final_stage5[4] ^ c_stage5[4];
            sum[5] <= p_final_stage5[5] ^ c_stage5[5];
            sum[6] <= p_final_stage5[6] ^ c_stage5[6];
            sum[7] <= p_final_stage5[7] ^ c_stage5[7];
        end
    end

endmodule