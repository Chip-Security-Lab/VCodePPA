//SystemVerilog
module ring_counter #(parameter WIDTH = 8) (
    input wire clock, reset, preset,
    output wire [WIDTH-1:0] count
);
    reg [WIDTH-1:0] shift_reg;
    
    always @(posedge clock) begin
        if (reset)
            shift_reg <= {WIDTH{1'b0}};
        else if (preset)
            shift_reg <= {{(WIDTH-1){1'b0}}, 1'b1};
        else
            shift_reg <= {shift_reg[0], shift_reg[WIDTH-1:1]};
    end
    
    assign count = shift_reg;
endmodule