module token_ring_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [WIDTH-1:0] token;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        token <= 1;
        grant_o <= 0;
    end else begin
        grant_o <= token & req_i;
        if(!(|(token & req_i)))  // No request for current token
            token <= {token[WIDTH-2:0], token[WIDTH-1]};
    end
end
endmodule
