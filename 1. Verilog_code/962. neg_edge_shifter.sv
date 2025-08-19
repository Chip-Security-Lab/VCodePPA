module neg_edge_shifter #(parameter LENGTH = 6) (
    input wire neg_clk,
    input wire d_in,
    input wire rstn,
    output wire [LENGTH-1:0] q_out
);
    reg [LENGTH-1:0] shift_reg;
    
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn)
            shift_reg <= {LENGTH{1'b0}};
        else
            shift_reg <= {d_in, shift_reg[LENGTH-1:1]};
    end
    
    assign q_out = shift_reg;
endmodule