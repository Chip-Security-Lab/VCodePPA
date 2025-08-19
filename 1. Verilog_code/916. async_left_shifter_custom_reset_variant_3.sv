//SystemVerilog
module async_left_shifter_custom_reset #(
    parameter WIDTH = 8,
    parameter RESET_VAL = 8'hA5
)(
    input                  rstn,
    input      [WIDTH-1:0] din,
    input      [$clog2(WIDTH)-1:0] shift,
    output     [WIDTH-1:0] dout
);
    wire [WIDTH-1:0] barrel_shifted;
    wire [WIDTH-1:0] reset_mux;
    
    // LUT-based barrel shifter implementation
    reg [WIDTH-1:0] shift_lut [0:WIDTH-1];
    integer i;
    
    always @(*) begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            shift_lut[i] = din << i;
        end
    end
    
    assign barrel_shifted = shift_lut[shift];
    assign reset_mux = rstn ? barrel_shifted : RESET_VAL;
    assign dout = reset_mux;
endmodule