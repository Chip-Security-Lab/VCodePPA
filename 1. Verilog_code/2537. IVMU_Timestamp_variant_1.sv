//SystemVerilog
module IVMU_Timestamp #(parameter TS_W=16) (
    input clk,
    input [TS_W-1:0] ts [0:3], // Array of 4 timestamps, only ts[0], ts[1], ts[2] are used
    output reg [1:0] sel
);

// Stage 1: Combinational comparisons
wire comp_ts0_lt_ts1;
wire comp_ts0_lt_ts2;
wire comp_ts1_lt_ts2;

assign comp_ts0_lt_ts1 = ts[0] < ts[1];
assign comp_ts0_lt_ts2 = ts[0] < ts[2];
assign comp_ts1_lt_ts2 = ts[1] < ts[2];

// Stage 1: Register comparison results
reg comp_ts0_lt_ts1_r;
reg comp_ts0_lt_ts2_r;
reg comp_ts1_lt_ts2_r;

always @(posedge clk) begin
    comp_ts0_lt_ts1_r <= comp_ts0_lt_ts1;
    comp_ts0_lt_ts2_r <= comp_ts0_lt_ts2;
    comp_ts1_lt_ts2_r <= comp_ts1_lt_ts2;
end

// Stage 2: Combinational logic for selection based on registered comparisons
wire [1:0] sel_next;

// Logic derived from original:
// sel <= (ts[0] < ts[1]) ? ((ts[0] < ts[2]) ? 0 : 2) : ((ts[1] < ts[2]) ? 1 : 2);
// Using registered comps:
// sel <= comp_ts0_lt_ts1_r ? (comp_ts0_lt_ts2_r ? 2'b00 : 2'b10) : (comp_ts1_lt_ts2_r ? 2'b01 : 2'b10);
assign sel_next = comp_ts0_lt_ts1_r ? (comp_ts0_lt_ts2_r ? 2'b00 : 2'b10) : (comp_ts1_lt_ts2_r ? 2'b01 : 2'b10);

// Stage 2: Register the final selection
always @(posedge clk) begin
    sel <= sel_next;
end

endmodule