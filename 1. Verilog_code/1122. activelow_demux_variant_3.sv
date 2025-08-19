//SystemVerilog
module activelow_demux (
    input wire data_in,                  // Input data (active high)
    input wire [1:0] addr,               // Address selection
    output wire [3:0] out_n              // Active-low outputs
);
    // Using continuous assignment for direct mapping
    // This eliminates the need for an intermediate register
    // and simplifies the logic path
    
    // When data_in is high, decode the address and set the appropriate bit
    // When data_in is low, all outputs are high (active-low outputs inactive)
    assign out_n[0] = ~(data_in && (addr == 2'b00));
    assign out_n[1] = ~(data_in && (addr == 2'b01));
    assign out_n[2] = ~(data_in && (addr == 2'b10));
    assign out_n[3] = ~(data_in && (addr == 2'b11));
    
endmodule