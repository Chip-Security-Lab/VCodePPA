module shift_dynamic_cfg #(parameter WIDTH=8) (
    input clk,
    input [1:0] cfg_mode, // 00-hold, 01-left, 10-right, 11-load
    input [WIDTH-1:0] cfg_data,
    output reg [WIDTH-1:0] dout
);
always @(posedge clk) begin
    case(cfg_mode)
        2'b01: dout <= {dout[WIDTH-2:0], 1'b0};
        2'b10: dout <= {1'b0, dout[WIDTH-1:1]};
        2'b11: dout <= cfg_data;
        default: dout <= dout;
    endcase
end
endmodule
