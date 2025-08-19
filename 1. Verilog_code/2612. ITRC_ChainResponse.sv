module ITRC_ChainResponse #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input ack,
    output reg [WIDTH-1:0] current_int
);
    wire [WIDTH-1:0] masked_src = int_src & ~current_int;
    
    always @(posedge clk) begin
        if (!rst_n) current_int <= 0;
        else if (ack)
            current_int <= {1'b0, current_int[WIDTH-1:1]};
        else if (!current_int[0])
            current_int <= masked_src ^ (masked_src - 1);
    end
endmodule