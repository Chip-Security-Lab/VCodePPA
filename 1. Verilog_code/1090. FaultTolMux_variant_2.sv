//SystemVerilog
module FaultTolMux #(parameter DW=8) (
    input clk,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);

reg [DW-1:0] primary_data_reg;
reg [DW-1:0] backup_data_reg;
reg [DW-1:0] din_mux_primary;
reg [DW-1:0] din_mux_backup;
reg [3:0] primary_data_high_reg;
reg [3:0] backup_data_high_reg;
reg primary_xor_bit;
reg backup_xor_bit;
reg mux_condition_reg;

// 并行前缀减法器4位子模块声明
wire [3:0] sel_inv;
ParallelPrefixSubtractor4 u_inv_sel (
    .a({2'b00, sel}), // zero-extend sel to 4 bits
    .b(4'b0000),
    .diff(sel_inv),
    .borrow_out()
);

// Pipeline Stage 1: Mux din
always @(posedge clk) begin
    din_mux_primary <= din[sel];
    din_mux_backup  <= din[sel_inv[1:0]];
end

// Pipeline Stage 2: Register muxed data and extract high bits
always @(posedge clk) begin
    primary_data_reg <= din_mux_primary;
    backup_data_reg  <= din_mux_backup;
    primary_data_high_reg <= din_mux_primary[7:4];
    backup_data_high_reg  <= din_mux_backup[7:4];
end

// Pipeline Stage 3: XOR and condition evaluation
always @(posedge clk) begin
    primary_xor_bit <= ^primary_data_high_reg;
    backup_xor_bit  <= ^backup_data_high_reg;
    mux_condition_reg <= ((^primary_data_high_reg) == primary_data_reg[3]);
end

// Pipeline Stage 4: Output logic
always @(posedge clk) begin
    if (mux_condition_reg) begin
        dout <= primary_data_reg;
    end else begin
        dout <= backup_data_reg;
    end
    error <= (primary_data_reg != backup_data_reg);
end

endmodule

// 4位并行前缀减法器模块
module ParallelPrefixSubtractor4 (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] diff,
    output       borrow_out
);

    wire [3:0] g, p;
    wire [4:0] c;

    assign g = (~a) & b;      // generate
    assign p = ~(a ^ b);      // propagate (for subtraction, p=~(a^b))

    assign c[0] = 1'b0;

    // Kogge-Stone style prefix computation
    wire [3:0] g1, p1, g2, p2, g3;

    // Level 1
    assign g1[0] = g[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign g1[3] = g[3] | (p[3] & g[2]);

    // Level 2
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign g2[2] = g1[2] | (p[2] & g1[0]);
    assign g2[3] = g1[3] | (p[3] & g1[1]);

    // Level 3
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3] | (p[3] & g2[0]);

    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g1[1] | (p[1] & c[0]);
    assign c[3] = g2[2] | (p[2] & c[0]);
    assign c[4] = g3[3] | (p[3] & c[0]);

    assign diff[0] = a[0] ^ b[0] ^ c[0];
    assign diff[1] = a[1] ^ b[1] ^ c[1];
    assign diff[2] = a[2] ^ b[2] ^ c[2];
    assign diff[3] = a[3] ^ b[3] ^ c[3];

    assign borrow_out = c[4];

endmodule