module sipo_register #(parameter N = 8) (
    input wire clk, rst, en,
    input wire s_in,
    output wire [N-1:0] p_out
);
    reg [N-1:0] shift_register;
    
    always @(negedge clk) begin  // Negative edge triggered
        if (rst)
            shift_register <= 0;
        else if (en)
            shift_register <= {shift_register[N-2:0], s_in};
    end
    
    assign p_out = shift_register;
endmodule