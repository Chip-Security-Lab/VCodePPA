module shadow_reg_mask #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in, mask,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow_reg;
    always @(posedge clk) begin
        if(en) shadow_reg <= (shadow_reg & ~mask) | (data_in & mask);
        data_out <= shadow_reg;
    end
endmodule