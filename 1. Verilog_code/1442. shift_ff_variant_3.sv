//SystemVerilog
module shift_ff (
    input clk, rstn, 
    input sin,
    output reg q
);
    reg sin_reg;
    
    always @(posedge clk)
        sin_reg <= sin;
        
    always @(posedge clk)
        q <= (!rstn) ? 1'b0 : sin_reg;
endmodule