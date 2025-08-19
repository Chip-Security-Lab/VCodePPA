//SystemVerilog
module pulse_sync #(
    parameter DST_CLK_RATIO = 2
)(
    input src_clk,
    input dst_clk,
    input src_pulse,
    input src_rst_n,    // Added reset signal for src domain
    input dst_rst_n,    // Added reset signal for dst domain
    output dst_pulse
);

// Source clock domain
reg src_flag;
reg src_pulse_stage1, src_pulse_valid;

// Destination clock domain
reg [2:0] sync_chain;
reg dst_flag;
reg dst_pulse_stage1, dst_pulse_stage2;
reg dst_valid_stage1, dst_valid_stage2;

// Pipeline Stage 1: Source domain capture
always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
        src_flag <= 1'b0;
        src_pulse_stage1 <= 1'b0;
        src_pulse_valid <= 1'b0;
    end else begin
        src_pulse_stage1 <= src_pulse;
        src_pulse_valid <= src_pulse;
        
        if (src_pulse_valid) begin
            src_flag <= ~src_flag;
        end
    end
end

// Pipeline Stage 2: Clock domain crossing synchronization
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        sync_chain <= 3'b000;
        dst_flag <= 1'b0;
        dst_pulse_stage1 <= 1'b0;
        dst_valid_stage1 <= 1'b0;
    end else begin
        // Synchronization chain to safely cross clock domains
        sync_chain <= {sync_chain[1:0], src_flag};
        
        // Store previous value for edge detection
        dst_flag <= sync_chain[2];
        
        // Detect changes and generate pulse - Stage 1
        dst_pulse_stage1 <= (sync_chain[2] ^ dst_flag);
        dst_valid_stage1 <= 1'b1;
    end
end

// Pipeline Stage 3: Output generation
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        dst_pulse_stage2 <= 1'b0;
        dst_valid_stage2 <= 1'b0;
    end else begin
        // Pass through the result to the final stage
        dst_pulse_stage2 <= dst_pulse_stage1;
        dst_valid_stage2 <= dst_valid_stage1;
    end
end

// Final output
assign dst_pulse = dst_pulse_stage2 & dst_valid_stage2;

endmodule