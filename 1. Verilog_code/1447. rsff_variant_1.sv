//SystemVerilog
module rsff (
    input clk, set, reset,
    output reg q
);
    reg set_reg, reset_reg;
    reg next_q;
    
    // Register the inputs to reduce input path delay
    always @(posedge clk) begin
        set_reg <= set;
        reset_reg <= reset;
    end
    
    // Combinational logic to determine next state
    always @(*) begin
        if (set_reg && !reset_reg)
            next_q = 1'b1;
        else if (!set_reg && reset_reg)
            next_q = 1'b0;
        else if (set_reg && reset_reg)
            next_q = 1'bx;
        else
            next_q = q;
    end
    
    // Output register
    always @(posedge clk) begin
        q <= next_q;
    end
endmodule