module p2s_buffer (
    input wire clk,
    input wire load,
    input wire shift,
    input wire [7:0] parallel_in,
    output wire serial_out
);
    reg [7:0] shift_reg;
    
    always @(posedge clk) begin
        if (load)
            shift_reg <= parallel_in;
        else if (shift)
            shift_reg <= {shift_reg[6:0], 1'b0};
    end
    
    assign serial_out = shift_reg[7];
endmodule