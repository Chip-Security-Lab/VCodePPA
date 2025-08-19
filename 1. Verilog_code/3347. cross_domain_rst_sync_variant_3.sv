//SystemVerilog
module cross_domain_rst_sync (
    input  wire clk_src,
    input  wire clk_dst,
    input  wire async_rst_n,
    output wire sync_rst_n_dst
);
    reg rst_src_meta;
    reg [1:0] rst_dst_sync;

    // Source clock domain: metastability protection
    always @(posedge clk_src or negedge async_rst_n) begin
        rst_src_meta <= (!async_rst_n) ? 1'b0 : 1'b1;
    end

    // Destination clock domain: 2-stage synchronizer
    always @(posedge clk_dst or negedge async_rst_n) begin
        rst_dst_sync <= (!async_rst_n) ? 2'b00 : {rst_dst_sync[0], rst_src_meta};
    end

    assign sync_rst_n_dst = rst_dst_sync[1];
endmodule