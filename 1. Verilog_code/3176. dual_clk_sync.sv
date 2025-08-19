module dual_clk_sync(
    input src_clk,
    input dst_clk,
    input rst_n,
    input pulse_in,
    output reg pulse_out
);
    reg toggle_ff;
    reg [1:0] sync_ff;
    reg sync_prev;
    
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n)
            toggle_ff <= 1'b0;
        else if (pulse_in)
            toggle_ff <= ~toggle_ff;
    end
    
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff <= 2'b00;
            sync_prev <= 1'b0;
            pulse_out <= 1'b0;
        end else begin
            sync_ff <= {sync_ff[0], toggle_ff};
            sync_prev <= sync_ff[1];
            pulse_out <= sync_ff[1] ^ sync_prev;
        end
    end
endmodule