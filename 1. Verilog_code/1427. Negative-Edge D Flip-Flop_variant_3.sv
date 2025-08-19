//SystemVerilog
module neg_edge_d_ff (
    input wire clk,
    input wire d_in,
    output wire q_out
);
    reg d_in_reg;
    
    always @(negedge clk) begin
        d_in_reg <= d_in;
    end
    
    assign q_out = d_in_reg;
    
endmodule