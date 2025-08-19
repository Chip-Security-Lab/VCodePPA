//SystemVerilog
module log_to_linear #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input wire                  clk,
    input wire                  rst_n,
    input wire  [WIDTH-1:0]     log_in,
    output reg  [WIDTH-1:0]     linear_out
);

    // ---------------- Pipeline Stage 1: Input Capture ----------------
    reg [WIDTH-1:0] log_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            log_in_stage1 <= {WIDTH{1'b0}};
        else
            log_in_stage1 <= log_in;
    end

    // ---------------- Pipeline Stage 2: LUT Address Decode ----------------
    reg [WIDTH-1:0] log_in_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            log_in_stage2 <= {WIDTH{1'b0}};
        else
            log_in_stage2 <= log_in_stage1;
    end

    // ---------------- Pipeline Stage 3: LUT Output Fetch ----------------
    reg [WIDTH-1:0] lut_data_stage3;
    reg [WIDTH-1:0] lut [0:LUT_SIZE-1];

    // LUT Initialization
    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut[i] = exp_shift_lut(i);
        end
    end

    // Move output register back to this stage (backward retiming)
    reg [WIDTH-1:0] linear_out_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lut_data_stage3 <= {WIDTH{1'b0}};
        else if (log_in_stage2 < LUT_SIZE)
            lut_data_stage3 <= lut[log_in_stage2];
        else
            lut_data_stage3 <= {WIDTH{1'b1}};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            linear_out_stage4 <= {WIDTH{1'b0}};
        else
            linear_out_stage4 <= lut_data_stage3;
    end

    // Output register moved backward, assign directly
    always @(*) begin
        linear_out = linear_out_stage4;
    end

    // ---------------- 8-bit Carry Lookahead Adder (CLA) ----------------
    function [WIDTH-1:0] cla_adder_8bit;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        input             cin;
        reg   [WIDTH-1:0] p, g;
        reg   [WIDTH:0]   c;
        integer           k;
        begin
            p = a ^ b;
            g = a & b;
            c[0] = cin;
            c[1] = g[0] | (p[0] & c[0]);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
            c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) |
                   (p[3] & p[2] & p[1] & p[0] & c[0]);
            c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) |
                   (p[4] & p[3] & p[2] & p[1] & g[0]) |
                   (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) |
                   (p[5] & p[4] & p[3] & p[2] & g[1]) |
                   (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) |
                   (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) |
                   (p[6] & p[5] & p[4] & p[3] & g[2]) |
                   (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) |
                   (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) |
                   (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) |
                   (p[7] & p[6] & p[5] & p[4] & g[3]) |
                   (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) |
                   (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) |
                   (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) |
                   (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            for (k = 0; k < WIDTH; k = k + 1) begin
                cla_adder_8bit[k] = p[k] ^ c[k];
            end
        end
    endfunction

    // ---------------- Exponential LUT Value Generation ----------------
    function [WIDTH-1:0] exp_shift_lut;
        input integer idx;
        reg   [WIDTH-1:0] base;
        integer           shift_amt;
        integer           j;
        begin
            base      = 8'b00000001;
            shift_amt = idx / 2;
            for (j = 0; j < shift_amt; j = j + 1) begin
                base = cla_adder_8bit(base, base, 1'b0);
            end
            exp_shift_lut = base;
        end
    endfunction

endmodule