module AsyncLatch #(parameter WIDTH=4) (
    input en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
always @* if(en) data_out = data_in;
endmodule