module piso_shifter(
    input clk, rst, load,
    input [7:0] parallel_in,
    output serial_out
);
    reg [7:0] shift_reg;
    always @(posedge clk) begin
        if (rst)
            shift_reg <= 8'b0;
        else if (load)
            shift_reg <= parallel_in;
        else
            shift_reg <= {shift_reg[6:0], 1'b0};
    end
    assign serial_out = shift_reg[7];
endmodule