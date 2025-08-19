module cascade_div #(parameter DEPTH=3) (
    input clk, en,
    output [DEPTH:0] div_out
);
wire [DEPTH:0] clk_div;
assign clk_div[0] = clk;
assign div_out = clk_div;

genvar i;
generate
for(i=0;i<DEPTH;i++) begin : stage
    reg [1:0] cnt;
    
    always @(posedge clk_div[i]) begin
        if(!en) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end
    assign clk_div[i+1] = cnt[1];
end
endgenerate
endmodule