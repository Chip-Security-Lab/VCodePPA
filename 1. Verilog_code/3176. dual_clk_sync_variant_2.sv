//SystemVerilog
module dual_clk_sync(
    input src_clk,
    input dst_clk,
    input rst_n,
    input pulse_in,
    output reg pulse_out
);
    reg toggle_ff;
    reg [1:0] sync_ff;  // Reduced to 2 stages with optimized edge detection
    
    // Source clock domain with optimized toggle logic
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n)
            toggle_ff <= 1'b0;
        else
            toggle_ff <= pulse_in ? ~toggle_ff : toggle_ff;
    end
    
    // Destination clock domain with optimized synchronization
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff <= 2'b00;
            pulse_out <= 1'b0;
        end else begin
            sync_ff <= {sync_ff[0], toggle_ff};
            pulse_out <= sync_ff[1] ^ sync_ff[0];
        end
    end
endmodule