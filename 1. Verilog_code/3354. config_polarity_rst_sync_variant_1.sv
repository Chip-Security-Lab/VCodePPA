//SystemVerilog
module config_polarity_rst_sync (
    input  wire clk,
    input  wire reset_in,
    input  wire active_high,
    output reg  sync_reset
);
    reg [1:0] sync_chain;
    wire      normalized_reset;
    
    // Optimize combinational logic by using conditional operator
    // This reduces logic depth by implementing a simple multiplexer
    assign normalized_reset = active_high ? reset_in : ~reset_in;
    
    // Synchronization chain registers
    always @(posedge clk) begin
        sync_chain <= {sync_chain[0], normalized_reset};
    end
    
    // Final output stage - optimize with direct assignment
    // Reuse the same logic structure as the input stage
    always @(posedge clk) begin
        sync_reset <= active_high ? sync_chain[1] : ~sync_chain[1];
    end
endmodule