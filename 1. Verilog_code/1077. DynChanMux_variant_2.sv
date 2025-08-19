//SystemVerilog
module DynChanMux #(parameter DW = 16, MAX_CH = 8) (
    input wire clk,
    input wire [$clog2(MAX_CH)-1:0] ch_num,
    input wire [(MAX_CH*DW)-1:0] data,
    output reg [DW-1:0] out
);

localparam CH_WIDTH = $clog2(MAX_CH);

reg [DW-1:0] mux_out;

always @(*) begin
    casez (ch_num)
        0 : mux_out = data[DW*1-1:DW*0];
        1 : mux_out = data[DW*2-1:DW*1];
        2 : mux_out = data[DW*3-1:DW*2];
        3 : mux_out = data[DW*4-1:DW*3];
        4 : mux_out = data[DW*5-1:DW*4];
        5 : mux_out = data[DW*6-1:DW*5];
        6 : mux_out = data[DW*7-1:DW*6];
        7 : mux_out = data[DW*8-1:DW*7];
        default: mux_out = {DW{1'b0}};
    endcase
end

always @(posedge clk) begin
    out <= mux_out;
end

endmodule