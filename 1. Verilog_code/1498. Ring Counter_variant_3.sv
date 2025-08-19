//SystemVerilog
module ring_counter #(parameter WIDTH = 4) (
    input wire clock, reset, preset,
    output wire [WIDTH-1:0] count
);
    reg [WIDTH-1:0] shift_reg;
    wire next_bit;
    
    // Forward retiming: Moving the first bit logic ahead of the register chain
    assign next_bit = shift_reg[WIDTH-1];
    
    always @(posedge clock) begin
        case ({reset, preset})
            2'b10: shift_reg <= {1'b0, {(WIDTH-1){1'b0}}};
            2'b01: shift_reg <= {1'b1, {(WIDTH-1){1'b0}}};
            2'b00: shift_reg <= {shift_reg[WIDTH-2:0], next_bit};
            2'b11: shift_reg <= {1'b0, {(WIDTH-1){1'b0}}}; // 优先考虑reset
        endcase
    end
    
    assign count = shift_reg;
endmodule