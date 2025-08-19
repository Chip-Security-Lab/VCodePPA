//SystemVerilog
module BurstArbiter #(parameter BURST_LEN=4) (
    input clk, rst, en,
    input [3:0] req,
    output reg [3:0] grant
);

// Pipeline stages
reg [1:0] burst_cnt;
reg [3:0] grant_next;
reg [1:0] burst_cnt_next;

// Request priority encoder
wire [3:0] priority_grant = req & -req;

// Burst control logic
wire burst_complete = (burst_cnt == BURST_LEN-1);
wire [1:0] burst_cnt_inc = burst_cnt + 1;

// Next state logic
always @(*) begin
    if (|grant) begin
        grant_next = burst_complete ? priority_grant : grant;
        burst_cnt_next = burst_complete ? 0 : burst_cnt_inc;
    end else begin
        grant_next = priority_grant;
        burst_cnt_next = 0;
    end
end

// State update
always @(posedge clk) begin
    if (rst) begin
        grant <= 0;
        burst_cnt <= 0;
    end else if (en) begin
        grant <= grant_next;
        burst_cnt <= burst_cnt_next;
    end
end

endmodule