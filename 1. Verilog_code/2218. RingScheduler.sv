module RingScheduler #(parameter BUF_SIZE=8) (
    input clk, rst_n,
    output reg [BUF_SIZE-1:0] events
);
reg [2:0] ptr;
always @(posedge clk) begin
    if (!rst_n) begin
        ptr <= 0;
        events <= 1;
    end else begin
        ptr <= ptr + 1;
        events <= (events << 1) | (events[BUF_SIZE-1]);
    end
end
endmodule