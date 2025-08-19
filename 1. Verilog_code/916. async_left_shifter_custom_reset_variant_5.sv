//SystemVerilog
module async_left_shifter_custom_reset #(
    parameter WIDTH = 8,
    parameter RESET_VAL = 8'hA5  // Custom reset pattern
)(
    input                  rstn,
    input      [WIDTH-1:0] din,
    input      [$clog2(WIDTH)-1:0] shift,
    output     [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] shifted_data;
    
    // Lookup table for shift operations
    reg [WIDTH-1:0] shift_lut [0:WIDTH-1];
    
    // Initialize lookup table
    initial begin
        shift_lut[0] = 8'b00000001;
        shift_lut[1] = 8'b00000010;
        shift_lut[2] = 8'b00000100;
        shift_lut[3] = 8'b00001000;
        shift_lut[4] = 8'b00010000;
        shift_lut[5] = 8'b00100000;
        shift_lut[6] = 8'b01000000;
        shift_lut[7] = 8'b10000000;
    end
    
    // Async reset with custom reset value and lookup table-based shift
    always @(*) begin
        if (!rstn)
            shifted_data = RESET_VAL;
        else
            shifted_data = din * shift_lut[shift];
    end
    
    assign dout = shifted_data;
endmodule