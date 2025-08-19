module config_reg_decoder #(
    parameter REGISTERED_OUTPUT = 1
)(
    input clk,
    input [1:0] addr,
    output [3:0] dec_out
);
    reg [3:0] dec_reg;
    wire [3:0] dec_comb;
    
    assign dec_comb = (4'b0001 << addr);
    
    always @(posedge clk)
        dec_reg <= dec_comb;
        
    assign dec_out = REGISTERED_OUTPUT ? dec_reg : dec_comb;
endmodule