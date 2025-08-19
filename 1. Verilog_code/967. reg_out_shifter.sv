module reg_out_shifter (
    input clk, reset_n,
    input serial_in,
    output reg serial_out
);
    reg [3:0] shift;
    
    // Shift register
    always @(posedge clk) begin
        if (!reset_n)
            shift <= 4'b0000;
        else
            shift <= {serial_in, shift[3:1]};
    end
    
    // Registered output
    always @(posedge clk) begin
        if (!reset_n)
            serial_out <= 1'b0;
        else
            serial_out <= shift[0];
    end
endmodule
