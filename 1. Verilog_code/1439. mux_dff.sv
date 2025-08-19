module mux_dff (
    input clk, sel,
    input d0, d1,
    output reg q
);
always @(posedge clk) begin
    q <= sel ? d1 : d0;
end
endmodule