//SystemVerilog
module dual_clk_sync(
    input src_clk,
    input dst_clk,
    input rst_n,
    input pulse_in,
    output reg pulse_out
);
    // Source clock domain
    reg pulse_in_stage1;
    reg toggle_ff_stage1;
    reg toggle_ff_stage2;
    
    // Destination clock domain
    reg [2:0] sync_ff;
    reg sync_prev_stage1;
    reg sync_prev_stage2;
    reg pulse_out_stage1;
    
    // Source clock domain pipeline
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_in_stage1 <= 1'b0;
            toggle_ff_stage1 <= 1'b0;
            toggle_ff_stage2 <= 1'b0;
        end else begin
            pulse_in_stage1 <= pulse_in;
            
            if (pulse_in_stage1)
                toggle_ff_stage1 <= ~toggle_ff_stage2;
            
            toggle_ff_stage2 <= toggle_ff_stage1;
        end
    end
    
    // Destination clock domain pipeline
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff <= 3'b000;
            sync_prev_stage1 <= 1'b0;
            sync_prev_stage2 <= 1'b0;
            pulse_out_stage1 <= 1'b0;
            pulse_out <= 1'b0;
        end else begin
            // Extended synchronizer chain
            sync_ff <= {sync_ff[1:0], toggle_ff_stage2};
            
            // Multi-stage edge detection pipeline
            sync_prev_stage1 <= sync_ff[2];
            sync_prev_stage2 <= sync_prev_stage1;
            
            // Edge detection split into stages
            pulse_out_stage1 <= sync_ff[2] ^ sync_prev_stage2;
            pulse_out <= pulse_out_stage1;
        end
    end
endmodule