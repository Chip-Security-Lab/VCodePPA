module data_encrypt #(parameter DW=16) (
    input clk, en,
    input [DW-1:0] din,
    input [DW-1:0] key,
    output reg [DW-1:0] dout
);
    always @(posedge clk) if(en) begin
        dout <= {din[7:0], din[15:8]} ^ key;
    end
endmodule
