//SystemVerilog
module reset_cdc_sync(
    input  wire dst_clk,
    input  wire async_rst_in,
    output wire synced_rst
);
    // Two-stage synchronizer
    (* ASYNC_REG = "TRUE" *) reg  rst_meta;
    (* ASYNC_REG = "TRUE" *) reg  rst_sync;

    // Generate synchronized reset using conditional operator
    always @(posedge dst_clk or posedge async_rst_in) begin
        rst_meta <= async_rst_in ? 1'b1 : 1'b0;
        rst_sync <= async_rst_in ? 1'b1 : rst_meta;
    end

    // Drive output as wire instead of reg for better timing
    assign synced_rst = rst_sync;
endmodule