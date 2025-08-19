module serialize_reg(
    input clk, reset,
    input [7:0] parallel_in,
    input load, shift_out,
    output reg [7:0] p_out,
    output serial_out
);
    always @(posedge clk) begin
        if (reset)
            p_out <= 8'b0;
        else if (load)
            p_out <= parallel_in;
        else if (shift_out)
            p_out <= {p_out[6:0], 1'b0};
    end
    
    assign serial_out = p_out[7];  // MSB first
endmodule
