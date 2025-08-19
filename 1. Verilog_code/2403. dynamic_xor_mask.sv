module dynamic_xor_mask #(
    parameter WIDTH = 64
)(
    input clk, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] mask_reg;
    
    always @(posedge clk) begin
        if (en) begin
            mask_reg <= mask_reg ^ 32'h9E3779B9;
            data_out <= data_in ^ mask_reg;
        end
    end
endmodule
