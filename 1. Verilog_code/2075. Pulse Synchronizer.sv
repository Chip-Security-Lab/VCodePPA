module pulse_sync (
    input wire src_clk, dst_clk, rst_n,
    input wire pulse_in,
    output wire pulse_out
);
    reg toggle_src;
    reg [2:0] sync_dst;
    
    // Source domain toggler
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) toggle_src <= 1'b0;
        else if (pulse_in) toggle_src <= ~toggle_src;
    end
    
    // Destination domain synchronizer
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) sync_dst <= 3'b0;
        else sync_dst <= {sync_dst[1:0], toggle_src};
    end
    
    // Edge detector for output pulse
    assign pulse_out = sync_dst[2] ^ sync_dst[1];
endmodule