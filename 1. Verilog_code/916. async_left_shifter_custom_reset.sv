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
    
    // Async reset with custom reset value
    always @(*) begin
        if (!rstn)
            shifted_data = RESET_VAL;
        else
            shifted_data = din << shift;
    end
    
    assign dout = shifted_data;
endmodule