//SystemVerilog
// Top-level module
module fixed_encoder (
    input      [7:0] symbol,
    input            valid_in,
    output     [3:0] code,
    output           valid_out
);
    // Directly use symbol[3:0] without intermediate module
    wire [3:0] symbol_lower = symbol[3:0];
    
    // Simplified encoding algorithm
    wire [3:0] encoded_value = symbol_lower[3] ? (4'h7 - symbol_lower[2:0]) : (4'h8 | symbol_lower[2:0]);
    
    // Simplified output control
    assign code = valid_in ? encoded_value : 4'h0;
    assign valid_out = valid_in;
    
endmodule