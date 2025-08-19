//SystemVerilog
module ser2par_pipelined #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                en,
    input  wire                ser_in,
    output reg  [WIDTH-1:0]    par_out,
    output reg                 par_valid
);

    // Stage 1: Shift in serial input
    reg  [WIDTH-1:0] shift_reg_stage1;
    reg              valid_stage1;

    // Stage 2: Detect completion and output parallel data
    reg  [WIDTH-1:0] shift_reg_stage2;
    reg              valid_stage2;
    reg  [$clog2(WIDTH):0] bit_count_stage1;
    reg  [$clog2(WIDTH):0] bit_count_stage2;

    // Internal signals for parallel prefix subtractor
    reg  [WIDTH-1:0] minuend_reg;
    reg  [WIDTH-1:0] subtrahend_reg;
    wire [WIDTH-1:0] diff_pps;
    wire             borrow_pps;

    // Stage 1: Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1  <= {WIDTH{1'b0}};
            bit_count_stage1  <= 'd0;
            valid_stage1      <= 1'b0;
        end else begin
            if (en) begin
                shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], ser_in};
                if (bit_count_stage1 == WIDTH-1)
                    bit_count_stage1 <= 'd0;
                else
                    bit_count_stage1 <= bit_count_stage1 + 1'b1;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Register intermediate results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2  <= {WIDTH{1'b0}};
            bit_count_stage2  <= 'd0;
            valid_stage2      <= 1'b0;
            minuend_reg       <= {WIDTH{1'b0}};
            subtrahend_reg    <= {WIDTH{1'b0}};
        end else begin
            shift_reg_stage2  <= shift_reg_stage1;
            bit_count_stage2  <= bit_count_stage1;
            valid_stage2      <= valid_stage1;
            // Example: use shift_reg_stage1 as minuend, a constant as subtrahend for demonstration
            // Users should connect proper values as required by design
            minuend_reg       <= shift_reg_stage1;
            subtrahend_reg    <= 8'b00110011; // Example subtrahend, replace as needed
        end
    end

    // Output logic with parallel prefix subtractor
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            par_out   <= {WIDTH{1'b0}};
            par_valid <= 1'b0;
        end else begin
            if (valid_stage2 && (bit_count_stage2 == WIDTH-1)) begin
                par_out   <= diff_pps;
                par_valid <= 1'b1;
            end else begin
                par_valid <= 1'b0;
            end
        end
    end

    // 8-bit Parallel Prefix Subtractor
    parallel_prefix_subtractor_8bit u_pps8 (
        .a      (minuend_reg),
        .b      (subtrahend_reg),
        .diff   (diff_pps),
        .borrow (borrow_pps)
    );

endmodule

// 8-bit Parallel Prefix Subtractor (Kogge-Stone style)
module parallel_prefix_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff,
    output wire       borrow
);

    wire [7:0] p, g;
    wire [7:0] b_xor;
    wire [7:0] c; // borrow chain

    assign b_xor = b ^ 8'hFF; // 1's complement for subtraction (a - b = a + ~b + 1)
    assign p = a ^ b_xor;
    assign g = ~a & b_xor;

    // Kogge-Stone prefix tree for borrow (carry) computation
    wire [7:0] c0, c1, c2;

    // Stage 0
    assign c0[0] = g[0];
    assign c0[1] = g[1] | (p[1] & g[0]);
    assign c0[2] = g[2] | (p[2] & g[1]);
    assign c0[3] = g[3] | (p[3] & g[2]);
    assign c0[4] = g[4] | (p[4] & g[3]);
    assign c0[5] = g[5] | (p[5] & g[4]);
    assign c0[6] = g[6] | (p[6] & g[5]);
    assign c0[7] = g[7] | (p[7] & g[6]);

    // Stage 1
    assign c1[0] = c0[0];
    assign c1[1] = c0[1];
    assign c1[2] = c0[2] | (p[2] & c0[0]);
    assign c1[3] = c0[3] | (p[3] & c0[1]);
    assign c1[4] = c0[4] | (p[4] & c0[2]);
    assign c1[5] = c0[5] | (p[5] & c0[3]);
    assign c1[6] = c0[6] | (p[6] & c0[4]);
    assign c1[7] = c0[7] | (p[7] & c0[5]);

    // Stage 2
    assign c2[0] = c1[0];
    assign c2[1] = c1[1];
    assign c2[2] = c1[2];
    assign c2[3] = c1[3];
    assign c2[4] = c1[4] | (p[4] & c1[0]);
    assign c2[5] = c1[5] | (p[5] & c1[1]);
    assign c2[6] = c1[6] | (p[6] & c1[2]);
    assign c2[7] = c1[7] | (p[7] & c1[3]);

    // Borrow chain
    assign c[0] = 1'b1; // initial borrow in for two's complement subtraction
    assign c[1] = c2[0];
    assign c[2] = c2[1];
    assign c[3] = c2[2];
    assign c[4] = c2[3];
    assign c[5] = c2[4];
    assign c[6] = c2[5];
    assign c[7] = c2[6];

    assign diff[0] = p[0] ^ c[0];
    assign diff[1] = p[1] ^ c[1];
    assign diff[2] = p[2] ^ c[2];
    assign diff[3] = p[3] ^ c[3];
    assign diff[4] = p[4] ^ c[4];
    assign diff[5] = p[5] ^ c[5];
    assign diff[6] = p[6] ^ c[6];
    assign diff[7] = p[7] ^ c[7];

    assign borrow = c2[7] | (p[7] & c2[3]);

endmodule