module siso_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, data_in,
    output wire data_out
);
    reg [WIDTH-1:0] shift_reg;
    
    always @(posedge clk) begin
        if (rst)
            shift_reg <= {WIDTH{1'b0}};
        else
            shift_reg <= {shift_reg[WIDTH-2:0], data_in};
    end
    
    assign data_out = shift_reg[WIDTH-1];
endmodule