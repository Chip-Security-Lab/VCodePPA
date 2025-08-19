//SystemVerilog
// Top-level module: Hierarchical two-flop synchronizer (modularized)
module two_flop_sync #(parameter WIDTH = 8) (
    input  wire                clk_dst,
    input  wire                rst_n,
    input  wire [WIDTH-1:0]    data_src,
    output wire [WIDTH-1:0]    data_dst
);

    // Internal signal between synchronizer stages
    wire [WIDTH-1:0] meta_sync_data;

    // Instantiate first stage: meta-stability register
    sync_register #(
        .WIDTH(WIDTH)
    ) u_meta_sync (
        .clk    (clk_dst),
        .rst_n  (rst_n),
        .d      (data_src),
        .q      (meta_sync_data)
    );

    // Instantiate second stage: output register
    sync_register #(
        .WIDTH(WIDTH)
    ) u_output_sync (
        .clk    (clk_dst),
        .rst_n  (rst_n),
        .d      (meta_sync_data),
        .q      (data_dst)
    );

endmodule

// -----------------------------------------------------------------------------
// Module: sync_register
// Description: Single synchronizing register stage with asynchronous reset
// Parameters:
//   - WIDTH: Data bus width
// Purpose: Used as a single D-type flip-flop stage for synchronizer chains
// -----------------------------------------------------------------------------
module sync_register #(parameter WIDTH = 8) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire [WIDTH-1:0]    d,
    output reg  [WIDTH-1:0]    q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {WIDTH{1'b0}};
        end else begin
            q <= d;
        end
    end

endmodule