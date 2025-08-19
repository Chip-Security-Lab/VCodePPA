module activelow_demux (
    input wire data_in,                  // Input data (active high)
    input wire [1:0] addr,               // Address selection
    output wire [3:0] out_n              // Active-low outputs
);
    // Generate active-low outputs (inverted logic)
    wire [3:0] internal_demux;
    
    // Internal demux logic (standard active-high)
    assign internal_demux = (data_in) ? (1 << addr) : 4'b0;
    
    // Convert to active-low outputs
    assign out_n = ~internal_demux;
endmodule