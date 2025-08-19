module basic_right_shift #(parameter WIDTH = 8) (
    input wire clk,
    input wire reset_n,
    input wire serial_in,
    output wire serial_out
);
    reg [WIDTH-1:0] shift_reg;
    
    always @(posedge clk) begin
        if (!reset_n)
            shift_reg <= {WIDTH{1'b0}};
        else
            shift_reg <= {serial_in, shift_reg[WIDTH-1:1]};
    end
    
    assign serial_out = shift_reg[0];
endmodule