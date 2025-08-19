//SystemVerilog
module rsff (
    input clk, set, reset,
    output reg q
);

    reg set_reg, reset_reg;
    wire [1:0] control;
    
    // Register inputs to improve timing at input path
    always @(posedge clk) begin
        set_reg <= set;
        reset_reg <= reset;
    end
    
    // Create control signal from registered inputs
    assign control = {set_reg, reset_reg};
    
    // Main flip-flop logic with reduced combinational delay
    always @(posedge clk) begin
        case (control)
            2'b10: q <= 1'b1;
            2'b01: q <= 1'b0;
            2'b11: q <= 1'bx;
        endcase
    end
    
endmodule