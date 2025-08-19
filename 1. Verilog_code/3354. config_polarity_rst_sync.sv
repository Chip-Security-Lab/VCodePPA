module config_polarity_rst_sync (
    input  wire clk,
    input  wire reset_in,
    input  wire active_high,
    output wire sync_reset
);
    reg [1:0] sync_chain;
    wire      normalized_reset;
    
    assign normalized_reset = active_high ? reset_in : !reset_in;
    
    always @(posedge clk) begin
        sync_chain <= {sync_chain[0], normalized_reset};
    end
    
    assign sync_reset = active_high ? sync_chain[1] : !sync_chain[1];
endmodule