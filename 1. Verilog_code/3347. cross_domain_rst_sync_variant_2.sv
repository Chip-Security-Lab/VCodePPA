//SystemVerilog
// SystemVerilog

//-----------------------------------------------------------------------------
// rst_src_sync: Synchronizes asynchronous reset in the source clock domain
//-----------------------------------------------------------------------------
module rst_src_sync #(
    parameter RESET_ACTIVE_LOW = 1
)(
    input  wire clk_src,
    input  wire async_rst_n,
    output wire rst_src_sync_out
);
    reg rst_src_sync_reg;

    wire src_rst_asserted;

    // Combinational logic for reset assertion
    assign src_rst_asserted = async_rst_n ? 1'b1 : 1'b0;

    always @(posedge clk_src or negedge async_rst_n) begin
        if (!async_rst_n)
            rst_src_sync_reg <= 1'b0;
        else
            rst_src_sync_reg <= src_rst_asserted;
    end

    assign rst_src_sync_out = rst_src_sync_reg;
endmodule

//-----------------------------------------------------------------------------
// rst_dst_sync: 2-stage synchronizer for reset signal in the destination domain
//-----------------------------------------------------------------------------
module rst_dst_sync #(
    parameter RESET_ACTIVE_LOW = 1
)(
    input  wire clk_dst,
    input  wire async_rst_n,
    input  wire rst_src_sync_in,
    output wire sync_rst_n_dst
);
    reg rst_dst_meta, rst_dst_sync;

    always @(posedge clk_dst or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_dst_meta <= 1'b0;
            rst_dst_sync <= 1'b0;
        end else begin
            rst_dst_meta <= rst_src_sync_in;
            rst_dst_sync <= rst_dst_meta;
        end
    end

    assign sync_rst_n_dst = rst_dst_sync;
endmodule

//-----------------------------------------------------------------------------
// cross_domain_rst_sync: Top-level cross-domain reset synchronizer
//-----------------------------------------------------------------------------
module cross_domain_rst_sync (
    input  wire clk_src,
    input  wire clk_dst,
    input  wire async_rst_n,
    output wire sync_rst_n_dst
);
    // Internal signal for source domain synchronized reset
    wire rst_src_sync_out;

    // Source domain reset synchronizer instance
    rst_src_sync u_rst_src_sync (
        .clk_src         (clk_src),
        .async_rst_n     (async_rst_n),
        .rst_src_sync_out(rst_src_sync_out)
    );

    // Destination domain 2-stage synchronizer instance
    rst_dst_sync u_rst_dst_sync (
        .clk_dst         (clk_dst),
        .async_rst_n     (async_rst_n),
        .rst_src_sync_in (rst_src_sync_out),
        .sync_rst_n_dst  (sync_rst_n_dst)
    );
endmodule