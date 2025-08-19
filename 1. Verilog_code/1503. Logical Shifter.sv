module logical_shifter #(parameter W = 16) (
    input wire clock, reset_n, load, shift,
    input wire [W-1:0] data,
    output wire [W-1:0] q_out
);
    reg [W-1:0] q_reg;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            q_reg <= {W{1'b0}};
        else if (load)
            q_reg <= data;
        else if (shift)
            q_reg <= {1'b0, q_reg[W-1:1]};
    end
    
    assign q_out = q_reg;
endmodule
