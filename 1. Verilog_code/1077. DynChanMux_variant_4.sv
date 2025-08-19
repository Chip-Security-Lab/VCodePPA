//SystemVerilog
module DynChanMux #(parameter DW=16, MAX_CH=8) (
    input wire clk,
    input wire [$clog2(MAX_CH)-1:0] ch_num,
    input wire [(MAX_CH*DW)-1:0] data,
    output reg [DW-1:0] out
);

localparam CH_SEL_WIDTH = $clog2(MAX_CH);

reg [DW-1:0] mux_out;

always @* begin
    casez (ch_num)
        0 : mux_out = data[0*DW +: DW];
        1 : mux_out = data[1*DW +: DW];
        2 : mux_out = data[2*DW +: DW];
        3 : mux_out = data[3*DW +: DW];
        4 : mux_out = data[4*DW +: DW];
        5 : mux_out = data[5*DW +: DW];
        6 : mux_out = data[6*DW +: DW];
        7 : mux_out = data[7*DW +: DW];
        default: mux_out = {DW{1'b0}};
    endcase
end

always @(posedge clk) begin
    out <= mux_out;
end

endmodule