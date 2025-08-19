//SystemVerilog
module activelow_demux (
    input wire data_in,                  // Input data (active high)
    input wire [1:0] addr,               // Address selection
    output wire [3:0] out_n              // Active-low outputs
);
    // Direct combinational assignment using simplified boolean expressions
    assign out_n[0] = ~(data_in & (addr == 2'b00));
    assign out_n[1] = ~(data_in & (addr == 2'b01));
    assign out_n[2] = ~(data_in & (addr == 2'b10));
    assign out_n[3] = ~(data_in & (addr == 2'b11));
endmodule