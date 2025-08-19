module circular_buffer #(
    parameter DW = 16,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full,
    output empty
);
reg [DW-1:0] buffer [0:DEPTH-1];
reg [3:0] wptr, rptr;
wire [3:0] wptr_next = wptr + 1;
wire [3:0] rptr_next = rptr + 1;

assign full = (wptr[2:0] == rptr[2:0]) && (wptr[3] ^ rptr[3]);
assign empty = (wptr == rptr);

always @(posedge clk) begin
    if (rst) begin
        wptr <= 0;
        rptr <= 0;
    end else begin
        if (push && !full) begin
            buffer[wptr[2:0]] <= din;
            wptr <= wptr_next;
        end
        if (pop && !empty) begin
            rptr <= rptr_next;
        end
    end
end

assign dout = buffer[rptr[2:0]];
endmodule