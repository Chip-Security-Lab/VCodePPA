module serializer_mux (
    input wire clk,               // Clock signal
    input wire load,              // Load parallel data
    input wire [7:0] parallel_in, // Parallel input data
    output wire serial_out        // Serial output
);
    reg [7:0] shift_reg;
    
    always @(posedge clk) begin
        if (load)
            shift_reg <= parallel_in;  // Load parallel data
        else
            shift_reg <= {shift_reg[6:0], 1'b0};  // Shift left
    end
    
    assign serial_out = shift_reg[7];  // MSB as serial output
endmodule