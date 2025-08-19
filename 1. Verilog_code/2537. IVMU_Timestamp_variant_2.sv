//SystemVerilog
module IVMU_Timestamp #(parameter TS_W=16) (
    input clk,
    input [TS_W-1:0] ts [0:3],
    output reg [1:0] sel
);

always @(posedge clk) begin
    // Find the index of the minimum value among ts[0], ts[1], and ts[2]
    // with priority 0, then 1, then 2 in case of ties.
    if ((ts[0] < ts[1]) && (ts[0] < ts[2])) begin
        // ts[0] is strictly the minimum
        sel <= 2'b00;
    end else if ((ts[1] <= ts[0]) && (ts[1] < ts[2])) begin
        // ts[1] is less than or equal to ts[0] and strictly less than ts[2]
        // This handles cases where ts[1] is the minimum or tied with ts[0] as minimum,
        // and ts[1] is strictly less than ts[2]. Priority 1 over 2.
        sel <= 2'b01;
    end else begin
        // In all other cases, ts[2] is the minimum or tied for minimum,
        // and the conditions for sel=0 or sel=1 were not met based on priority.
        // This includes cases like ts[2] < ts[0] and ts[2] <= ts[1],
        // or ties where ts[2] is involved and has lowest priority (e.g., ts[0]=5, ts[1]=10, ts[2]=5 -> sel=2).
        sel <= 2'b10;
    end
end

endmodule