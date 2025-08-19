module ring_counter #(parameter WIDTH = 4) (
    input wire clock, reset, preset,
    output wire [WIDTH-1:0] count
);
    reg [WIDTH-1:0] shift_reg;
    
    always @(posedge clock) begin
        if (reset)
            shift_reg <= {1'b0, {(WIDTH-1){1'b0}}};
        else if (preset)
            shift_reg <= {1'b1, {(WIDTH-1){1'b0}}};
        else
            shift_reg <= {shift_reg[0], shift_reg[WIDTH-1:1]};
    end
    
    assign count = shift_reg;
endmodule