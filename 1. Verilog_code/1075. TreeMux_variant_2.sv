//SystemVerilog
module TreeMux #(parameter DW=8, N=8) (
    input [N-1:0][DW-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [DW-1:0] dout
);

    function [DW-1:0] borrow_subtractor_8bit;
        input [DW-1:0] minuend;
        input [DW-1:0] subtrahend;
        reg [DW-1:0] diff;
        reg borrow;
        integer i;
        begin
            borrow = 1'b0;
            for (i = 0; i < DW; i = i + 1) begin
                diff[i] = minuend[i] ^ subtrahend[i] ^ borrow;
                borrow = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow);
            end
            borrow_subtractor_8bit = diff;
        end
    endfunction

    generate
        if(N == 1) begin
            assign dout = din[0];
        end else begin
            wire [DW-1:0] low_data;
            wire [DW-1:0] high_data;
            wire [DW-1:0] mux_diff;
            assign low_data = din[sel[$clog2(N)-1:1]];
            assign high_data = din[sel];
            assign mux_diff = borrow_subtractor_8bit(high_data, low_data);
            assign dout = sel[0] ? high_data : mux_diff;
        end
    endgenerate

endmodule