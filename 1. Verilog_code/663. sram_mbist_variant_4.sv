//SystemVerilog
module sram_mbist #(
    parameter AW = 5,
    parameter DW = 8
)(
    input clk,
    input test_mode,
    output error_flag
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [AW:0] test_counter;
reg test_stage;
wire [DW-1:0] expected = test_stage ? {DW{1'b1}} : {DW{1'b0}};

// Lookup table for address calculation
reg [AW-1:0] addr_lut [0:31];  // 32 entries for 5-bit address
reg [AW-1:0] next_addr;

// Initialize lookup table
initial begin
    for (integer i = 0; i < 32; i = i + 1) begin
        addr_lut[i] = i;
    end
end

// Address calculation using lookup table - optimized for timing
always @(*) begin
    next_addr = addr_lut[test_counter[AW-1:0]];
end

// Split complex condition into simpler parts for better timing
wire counter_msb = test_counter[AW];
wire test_mode_active = test_mode;

// Pre-compute next test stage value
wire next_test_stage = test_stage ^ counter_msb;

always @(posedge clk) begin
    if (test_mode_active) begin
        test_counter <= test_counter + 1;
        test_stage <= next_test_stage;
        mem[next_addr] <= expected;
    end
end

// Optimize error detection logic
wire addr_match = mem[next_addr] === expected;
assign error_flag = test_mode_active & ~addr_match;

endmodule