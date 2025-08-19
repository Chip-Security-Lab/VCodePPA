//SystemVerilog
module dff_async (
    input clk, arst_n,
    input d,
    output reg q
);

reg d_internal;

always @(posedge clk or negedge arst_n) begin
    d_internal <= !arst_n ? 1'b0 : d;
    q <= !arst_n ? 1'b0 : d_internal;
end

endmodule