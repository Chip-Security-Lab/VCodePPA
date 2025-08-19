module MultiChanTimer #(parameter CH=4, DW=8) (
    input clk, rst_n,
    input [CH-1:0] chan_en,
    output [CH-1:0] trig_out
);
reg [DW-1:0] cnt[0:CH-1];
genvar i;
generate for(i=0; i<CH; i=i+1) begin : ch_gen
    always @(posedge clk)
        cnt[i] <= (!rst_n || trig_out[i]) ? 0 : (chan_en[i]) ? cnt[i] + 1 : cnt[i];
    assign trig_out[i] = (cnt[i] == {DW{1'b1}});
end endgenerate
endmodule