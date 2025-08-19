//SystemVerilog
// Top-level two-flop synchronizer with 8-bit parallel prefix subtractor (Buffer-Optimized)
module two_flop_sync #(parameter WIDTH = 8) (
    input  wire                  clk_dst,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      data_src,
    output wire [WIDTH-1:0]      data_dst
);
    // Internal signals
    wire [WIDTH-1:0] subtractor_a_raw;
    wire [WIDTH-1:0] subtractor_a_buf;
    wire [WIDTH-1:0] subtractor_b_raw;
    wire [WIDTH-1:0] subtractor_b_buf;
    wire [WIDTH-1:0] subtractor_result_raw;
    wire [WIDTH-1:0] subtractor_result_buf;
    wire [WIDTH-1:0] data_dst_buf;

    assign subtractor_a_raw = data_src;
    assign subtractor_b_raw = 8'b00110110; // Example value for demonstration

    // Buffer for high-fanout a signal
    fanout_buffer_reg #(.WIDTH(WIDTH)) u_buf_a (
        .clk   (clk_dst),
        .rst_n (rst_n),
        .din   (subtractor_a_raw),
        .dout  (subtractor_a_buf)
    );

    // Buffer for high-fanout b signal
    fanout_buffer_reg #(.WIDTH(WIDTH)) u_buf_b (
        .clk   (clk_dst),
        .rst_n (rst_n),
        .din   (subtractor_b_raw),
        .dout  (subtractor_b_buf)
    );

    // 8-bit Parallel Prefix Subtractor with input buffers
    parallel_prefix_subtractor_8bit u_parallel_prefix_subtractor_8bit (
        .a     (subtractor_a_buf),
        .b     (subtractor_b_buf),
        .clk   (clk_dst),
        .rst_n (rst_n),
        .diff  (subtractor_result_raw)
    );

    // Buffer for high-fanout diff signal
    fanout_buffer_reg #(.WIDTH(WIDTH)) u_buf_diff (
        .clk   (clk_dst),
        .rst_n (rst_n),
        .din   (subtractor_result_raw),
        .dout  (subtractor_result_buf)
    );

    // Two-Flop Synchronizer with input buffer
    two_flop_pipeline #(.WIDTH(WIDTH)) u_two_flop_pipeline (
        .clk      (clk_dst),
        .rst_n    (rst_n),
        .d_in     (subtractor_result_buf),
        .q_out    (data_dst_buf)
    );

    // Buffer for high-fanout q_out signal
    fanout_buffer_reg #(.WIDTH(WIDTH)) u_buf_qout (
        .clk   (clk_dst),
        .rst_n (rst_n),
        .din   (data_dst_buf),
        .dout  (data_dst)
    );

endmodule

//-----------------------------------------------------------------------------
// Fanout Buffer Register Module (Generic)
//-----------------------------------------------------------------------------
module fanout_buffer_reg #(parameter WIDTH = 8) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire [WIDTH-1:0]   din,
    output reg  [WIDTH-1:0]   dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {WIDTH{1'b0}};
        else
            dout <= din;
    end
endmodule

//-----------------------------------------------------------------------------
// Two-Flop Pipeline Register for Metastability Protection in Clock Domain Crossing
//-----------------------------------------------------------------------------
module two_flop_pipeline #(parameter WIDTH = 8) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [WIDTH-1:0]     d_in,
    output reg  [WIDTH-1:0]     q_out
);
    reg [WIDTH-1:0] meta_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            meta_reg <= {WIDTH{1'b0}};
            q_out    <= {WIDTH{1'b0}};
        end else begin
            meta_reg <= d_in;
            q_out    <= meta_reg;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 8-bit Parallel Prefix Subtractor (Kogge-Stone Style) with Buffers for High-Fanout Internal Signals
//-----------------------------------------------------------------------------
module parallel_prefix_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       clk,
    input  wire       rst_n,
    output wire [7:0] diff
);
    // Stage 1: Buffer a and b for fanout reduction
    reg [7:0] a_buf;
    reg [7:0] b_buf;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_buf <= 8'b0;
            b_buf <= 8'b0;
        end else begin
            a_buf <= a;
            b_buf <= b;
        end
    end

    // Stage 2: Bitwise inversion for two's complement subtraction, buffer b_inv
    reg [7:0] b_inv_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            b_inv_reg <= 8'b0;
        else
            b_inv_reg <= ~b_buf;
    end

    // Stage 3: Generate and propagate terms, buffer g and p
    reg [7:0] g_reg, p_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_reg <= 8'b0;
            p_reg <= 8'b0;
        end else begin
            g_reg[0] <= a_buf[0] & b_inv_reg[0];
            p_reg[0] <= a_buf[0] ^ b_inv_reg[0];
            g_reg[1] <= a_buf[1] & b_inv_reg[1];
            p_reg[1] <= a_buf[1] ^ b_inv_reg[1];
            g_reg[2] <= a_buf[2] & b_inv_reg[2];
            p_reg[2] <= a_buf[2] ^ b_inv_reg[2];
            g_reg[3] <= a_buf[3] & b_inv_reg[3];
            p_reg[3] <= a_buf[3] ^ b_inv_reg[3];
            g_reg[4] <= a_buf[4] & b_inv_reg[4];
            p_reg[4] <= a_buf[4] ^ b_inv_reg[4];
            g_reg[5] <= a_buf[5] & b_inv_reg[5];
            p_reg[5] <= a_buf[5] ^ b_inv_reg[5];
            g_reg[6] <= a_buf[6] & b_inv_reg[6];
            p_reg[6] <= a_buf[6] ^ b_inv_reg[6];
            g_reg[7] <= a_buf[7] & b_inv_reg[7];
            p_reg[7] <= a_buf[7] ^ b_inv_reg[7];
        end
    end

    // Stage 4: Parallel prefix computation for carries (Kogge-Stone)
    reg [7:0] carry_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_reg <= 8'b0;
        end else begin
            carry_reg[0] <= 1'b1;
            carry_reg[1] <= g_reg[0] | (p_reg[0] & carry_reg[0]);
            carry_reg[2] <= g_reg[1] | (p_reg[1] & carry_reg[1]);
            carry_reg[3] <= g_reg[2] | (p_reg[2] & carry_reg[2]);
            carry_reg[4] <= g_reg[3] | (p_reg[3] & carry_reg[3]);
            carry_reg[5] <= g_reg[4] | (p_reg[4] & carry_reg[4]);
            carry_reg[6] <= g_reg[5] | (p_reg[5] & carry_reg[5]);
            carry_reg[7] <= g_reg[6] | (p_reg[6] & carry_reg[6]);
        end
    end

    // Stage 5: Buffer for diff output
    reg [7:0] diff_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            diff_reg <= 8'b0;
        else begin
            diff_reg[0] <= a_buf[0] ^ b_inv_reg[0] ^ carry_reg[0];
            diff_reg[1] <= a_buf[1] ^ b_inv_reg[1] ^ carry_reg[1];
            diff_reg[2] <= a_buf[2] ^ b_inv_reg[2] ^ carry_reg[2];
            diff_reg[3] <= a_buf[3] ^ b_inv_reg[3] ^ carry_reg[3];
            diff_reg[4] <= a_buf[4] ^ b_inv_reg[4] ^ carry_reg[4];
            diff_reg[5] <= a_buf[5] ^ b_inv_reg[5] ^ carry_reg[5];
            diff_reg[6] <= a_buf[6] ^ b_inv_reg[6] ^ carry_reg[6];
            diff_reg[7] <= a_buf[7] ^ b_inv_reg[7] ^ carry_reg[7];
        end
    end

    assign diff = diff_reg;

endmodule