//SystemVerilog
module sram_dynamic #(
    parameter MAX_DEPTH = 1024,
    parameter DW = 32
)(
    input clk,
    input [31:0] config_word,
    input we,
    input [31:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// Pre-compute configuration parameters
wire [15:0] configured_width = config_word[15:0];
wire [15:0] configured_depth = config_word[31:16];

// Optimize width and depth calculations using parallel prefix
wire [15:0] actual_width;
wire [15:0] actual_depth;

// Parallel prefix width calculation
wire [15:0] width_gt_dw = (configured_width > DW) ? 16'h1 : 16'h0;
wire [15:0] width_eq_0 = (configured_width == 0) ? 16'h1 : 16'h0;
wire [15:0] width_sel = width_gt_dw | width_eq_0;
assign actual_width = width_sel[0] ? (width_eq_0[0] ? DW : DW) : configured_width;

// Parallel prefix depth calculation
wire [15:0] depth_gt_max = (configured_depth > MAX_DEPTH) ? 16'h1 : 16'h0;
wire [15:0] depth_eq_0 = (configured_depth == 0) ? 16'h1 : 16'h0;
wire [15:0] depth_sel = depth_gt_max | depth_eq_0;
assign actual_depth = depth_sel[0] ? (depth_eq_0[0] ? MAX_DEPTH : MAX_DEPTH) : configured_depth;

// Pre-compute masks using parallel prefix
wire [DW-1:0] width_mask;
wire [DW-1:0] inv_width_mask;

// Parallel prefix mask generation
genvar i;
generate
    for (i = 0; i < DW; i = i + 1) begin : mask_gen
        wire [DW-1:0] temp_mask = (i < actual_width) ? (1 << i) : 0;
        assign width_mask[i] = |temp_mask;
    end
endgenerate
assign inv_width_mask = ~width_mask;

// Memory array
reg [DW-1:0] mem [0:MAX_DEPTH-1];
reg [DW-1:0] read_data;

// Address validation using parallel prefix
wire addr_valid;
wire [31:0] addr_lt_depth = addr < actual_depth;
assign addr_valid = &addr_lt_depth;

// Write operation with optimized logic
always @(posedge clk) begin
    if (we && addr_valid) begin
        if (actual_width == DW) begin
            mem[addr] <= din;
        end else begin
            mem[addr] <= (mem[addr] & inv_width_mask) | (din & width_mask);
        end
    end
end

// Read operation with optimized logic
always @(posedge clk) begin
    if (addr_valid) begin
        read_data <= (actual_width == DW) ? mem[addr] : (mem[addr] & width_mask);
    end else begin
        read_data <= 0;
    end
end

assign dout = read_data;

endmodule