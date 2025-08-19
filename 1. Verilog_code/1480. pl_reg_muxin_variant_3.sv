//SystemVerilog
module pl_reg_muxin #(parameter W=4) (
    input clk, sel,
    input [W-1:0] d0, d1,
    output [W-1:0] q
);
    reg [W-1:0] d0_reg, d1_reg;
    reg sel_reg;
    
    always @(posedge clk) begin
        d0_reg <= d0;
        d1_reg <= d1;
        sel_reg <= sel;
    end
    
    assign q = sel_reg ? d1_reg : d0_reg;
endmodule