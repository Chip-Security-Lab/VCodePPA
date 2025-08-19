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
reg [AW:0] test_counter_stage1;
reg [AW:0] test_counter_stage2;
reg test_stage_stage1;
reg test_stage_stage2;

// Stage 1 expected value generation
wire [DW-1:0] expected_stage1;
wire [DW-1:0] expected_stage2;

// Optimized multiplexer for stage 1 expected value
wire [DW-1:0] stage1_ones = {DW{1'b1}};
wire [DW-1:0] stage1_zeros = {DW{1'b0}};
assign expected_stage1 = test_stage_stage1 ? stage1_ones : stage1_zeros;

// Optimized multiplexer for stage 2 expected value
wire [DW-1:0] stage2_ones = {DW{1'b1}};
wire [DW-1:0] stage2_zeros = {DW{1'b0}};
assign expected_stage2 = test_stage_stage2 ? stage2_ones : stage2_zeros;

// Stage 1: Counter and stage update with optimized logic
wire [AW:0] next_counter_stage1 = test_counter_stage1 + 1;
wire next_stage_stage1 = test_counter_stage1[AW] ? ~test_stage_stage1 : test_stage_stage1;

always @(posedge clk) begin
    if (test_mode) begin
        test_counter_stage1 <= next_counter_stage1;
        test_stage_stage1 <= next_stage_stage1;
    end
end

// Stage 2: Memory write and error check with optimized logic
wire [AW:0] next_counter_stage2 = test_counter_stage1;
wire next_stage_stage2 = test_stage_stage1;

always @(posedge clk) begin
    if (test_mode) begin
        test_counter_stage2 <= next_counter_stage2;
        test_stage_stage2 <= next_stage_stage2;
        mem[test_counter_stage2[AW-1:0]] <= expected_stage2;
    end
end

// Optimized error detection logic
wire [DW-1:0] current_mem_value = mem[test_counter_stage2[AW-1:0]];
wire error_check = (current_mem_value !== expected_stage2);
wire error_flag_mux = test_mode ? error_check : 1'b0;
assign error_flag = error_flag_mux;

endmodule