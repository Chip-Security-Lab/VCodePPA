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
reg [AW-1:0] addr_pipe;
reg [DW-1:0] expected_pipe;

// Barrel shifter implementation for expected value generation
wire [DW-1:0] expected;
genvar i;
generate
    for (i = 0; i < DW; i = i + 1) begin : expected_gen
        assign expected[i] = test_stage;
    end
endgenerate

// Optimized counter logic with barrel shifter structure
reg [AW:0] next_counter;
wire [AW:0] counter_shifted;
wire [AW:0] counter_plus_one;

// Barrel shifter for counter increment
assign counter_plus_one = test_counter + 1'b1;
assign counter_shifted = {counter_plus_one[AW-1:0], 1'b0};

// Next counter value calculation
always @(*) begin
    next_counter = test_counter;
    if (test_mode) begin
        if (test_counter[AW]) begin
            next_counter = {1'b0, test_counter[AW-1:0]};
        end else begin
            next_counter = counter_plus_one;
        end
    end
end

// Optimized memory access with barrel shifter
reg [AW-1:0] addr_shifted;
reg [DW-1:0] data_shifted;

always @(*) begin
    addr_shifted = test_counter[AW-1:0];
    data_shifted = expected;
end

always @(posedge clk) begin
    if (test_mode) begin
        test_counter <= next_counter;
        if (test_counter[AW]) test_stage <= ~test_stage;
        addr_pipe <= addr_shifted;
        expected_pipe <= data_shifted;
        mem[addr_shifted] <= data_shifted;
    end
end

// Error detection with optimized comparison
assign error_flag = test_mode ? 
    (mem[addr_pipe] !== expected_pipe) : 1'b0;
endmodule