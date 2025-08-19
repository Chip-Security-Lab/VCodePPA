module cross_domain_rst_sync (
    input  wire clk_src,
    input  wire clk_dst,
    input  wire async_rst_n,
    output wire sync_rst_n_dst
);
    reg rst_src_meta, rst_src_sync;
    reg rst_dst_meta, rst_dst_sync;
    
    always @(posedge clk_src or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_src_meta <= 1'b0;
            rst_src_sync <= 1'b0;
        end else begin
            rst_src_meta <= 1'b1;
            rst_src_sync <= rst_src_meta;
        end
    end
    
    always @(posedge clk_dst or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_dst_meta <= 1'b0;
            rst_dst_sync <= 1'b0;
        end else begin
            rst_dst_meta <= rst_src_sync;
            rst_dst_sync <= rst_dst_meta;
        end
    end
    
    assign sync_rst_n_dst = rst_dst_sync;
endmodule
