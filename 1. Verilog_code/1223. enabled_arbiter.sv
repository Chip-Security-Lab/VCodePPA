module enabled_arbiter #(WIDTH=4) (
    input clk, rst_n, en,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [WIDTH-1:0] mask;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        grant_o <= 0;
        mask <= 0;
    end else if(en) begin
        mask <= req_i & (~req_i + 1);
        grant_o <= mask;
    end
end
endmodule
