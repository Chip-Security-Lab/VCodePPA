//SystemVerilog
module Demux_TriState #(parameter DW=8, N=4) (
    inout [DW-1:0] bus,
    input [N-1:0] sel,
    input oe,
    output [N-1:0][DW-1:0] rx_data,
    input [N-1:0][DW-1:0] tx_data
);
    // Optimized transmit data using direct indexing for better timing
    // and reduced logic usage
    wire [DW-1:0] selected_tx_data;
    
    // Use array indexing instead of case statement for more efficient
    // resource utilization and potentially better timing
    assign selected_tx_data = (sel < N) ? tx_data[sel] : {DW{1'b0}};
    
    // Control the bus with tristate buffer
    assign bus = oe ? selected_tx_data : {DW{1'bz}};
    
    // Simplified receiver data assignment with direct comparison
    // This avoids the unnecessary two's complement calculation
    generate 
        genvar i;
        for(i=0; i<N; i=i+1) begin : rx_channel
            // Direct equality comparison is more efficient 
            // than two's complement addition
            wire sel_match = (sel == i);
            
            // Assign output based on selection match
            assign rx_data[i] = sel_match ? bus : {DW{1'b0}}; 
        end
    endgenerate
endmodule