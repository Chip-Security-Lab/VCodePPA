//SystemVerilog
module TimeSliceArbiter #(parameter SLICE_WIDTH=8) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire [3:0]              req,
    output reg  [3:0]              grant
);

// Pipeline registers
reg  [SLICE_WIDTH-1:0]             counter;
reg  [SLICE_WIDTH-1:0]             counter_next;
reg  [3:0]                         grant_next;

// Data path signals
wire [SLICE_WIDTH-1:0]             counter_plus_1;
wire [SLICE_WIDTH-1:0]             g, p;
wire [SLICE_WIDTH-1:0]             g_level1, p_level1;
wire [SLICE_WIDTH-1:0]             g_level2, p_level2;
wire [SLICE_WIDTH-1:0]             carry;

// Generate and Propagate computation
assign g = counter & 4'b0001;
assign p = counter ^ 4'b0001;

// First level of Brent-Kung adder
assign g_level1[0] = g[0];
assign p_level1[0] = p[0];
assign g_level1[1] = g[1] | (p[1] & g[0]);
assign p_level1[1] = p[1] & p[0];
assign g_level1[2] = g[2] | (p[2] & g[1]);
assign p_level1[2] = p[2] & p[1];
assign g_level1[3] = g[3] | (p[3] & g[2]);
assign p_level1[3] = p[3] & p[2];

// Second level of Brent-Kung adder
assign g_level2[0] = g_level1[0];
assign p_level2[0] = p_level1[0];
assign g_level2[1] = g_level1[1];
assign p_level2[1] = p_level1[1];
assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
assign p_level2[2] = p_level1[2] & p_level1[0];
assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
assign p_level2[3] = p_level1[3] & p_level1[1];

// Final carry computation
assign carry[0] = g_level2[0];
assign carry[1] = g_level2[1];
assign carry[2] = g_level2[2];
assign carry[3] = g_level2[3];

// Sum computation
assign counter_plus_1 = p ^ {carry[SLICE_WIDTH-2:0], 1'b0};

// Next counter value computation
always @(*) begin
    if (rst || counter == 4)
        counter_next = 0;
    else
        counter_next = counter_plus_1;
end

// Grant computation
always @(*) begin
    grant_next = req & (1 << counter[1:0]);
end

// Sequential logic
always @(posedge clk) begin
    counter <= counter_next;
    grant <= grant_next;
end

endmodule