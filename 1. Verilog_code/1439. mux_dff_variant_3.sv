//SystemVerilog
module mux_dff (
    input clk, sel,
    input d0, d1,
    output reg q
);
    reg d0_reg, d1_reg, sel_reg;
    
    // Register inputs first to reduce input-to-register delay
    always @(posedge clk) begin
        d0_reg <= d0;
        d1_reg <= d1;
        sel_reg <= sel;
    end
    
    // Perform multiplexing after registering the inputs
    always @(posedge clk) begin
        q <= sel_reg ? d1_reg : d0_reg;
    end
endmodule