module MuxInputShift #(parameter W=4) (
    input clk,
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    output reg [W-1:0] q
);
always @(posedge clk) begin
    case(sel)
        2'b00: q <= {q[W-2:0], d0[0]};
        2'b01: q <= {q[W-2:0], d1[0]};
        2'b10: q <= {d2, q[W-1:1]};
        2'b11: q <= d3;
    endcase
end
endmodule
