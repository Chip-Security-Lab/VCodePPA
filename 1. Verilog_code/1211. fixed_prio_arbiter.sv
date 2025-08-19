module fixed_prio_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) grant_o <= 0;
    else begin
        casex(req_i)
        4'bxxx1: grant_o <= 4'b0001;
        4'bxx10: grant_o <= 4'b0010;
        4'bx100: grant_o <= 4'b0100;
        4'b1000: grant_o <= 4'b1000;
        default: grant_o <= 0;
        endcase
    end
end
endmodule
