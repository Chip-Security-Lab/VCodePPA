module dff_en (
    input clk, rstn, en,
    input d,
    output reg q
);
always @(posedge clk) begin
    if (!rstn)  q <= 0;
    else if (en) q <= d;
end
endmodule