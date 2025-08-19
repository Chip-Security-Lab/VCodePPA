//SystemVerilog
module int_ctrl_error_log #(
    parameter ERR_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ERR_BITS-1:0] err_in,
    output reg [ERR_BITS-1:0] err_log
);

always @(posedge clk)
    err_log <= rst ? {ERR_BITS{1'b0}} : (err_log | err_in);

endmodule