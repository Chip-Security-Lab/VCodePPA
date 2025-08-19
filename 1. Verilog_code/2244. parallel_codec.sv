module parallel_codec #(
    parameter DW=16, AW=4, DEPTH=8
)(
    input clk, valid, ready,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg ack
);
    reg [DW-1:0] buffer [0:DEPTH-1];
    reg [AW-1:0] wr_ptr, rd_ptr;
    always @(posedge clk) begin
        if(valid && ready) begin
            buffer[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
        ack <= (wr_ptr != rd_ptr);
    end
endmodule