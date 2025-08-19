//SystemVerilog
module cam #(
    parameter DW = 16,
    parameter ENTRIES = 32
)(
    input clk,
    input rst_n,
    input we,
    input [DW-1:0] wr_data,
    input [4:0] wr_addr,
    input [DW-1:0] match_data,
    input match_valid,
    output reg [ENTRIES-1:0] match_lines,
    output reg match_ready
);

// Pipeline registers
reg [DW-1:0] match_data_stage1;
reg [DW-1:0] match_data_stage2;
reg [DW-1:0] cam_array [0:ENTRIES-1];
reg [ENTRIES-1:0] match_result_stage1;
reg [ENTRIES-1:0] match_result_stage2;
reg valid_stage1;
reg valid_stage2;

integer i;

// Write logic
always @(posedge clk) begin
    if (we) cam_array[wr_addr] <= wr_data;
end

// Stage 1: Compare operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        match_data_stage1 <= 0;
        valid_stage1 <= 0;
        match_result_stage1 <= 0;
    end else begin
        match_data_stage1 <= match_data;
        valid_stage1 <= match_valid;
        for (i=0; i<ENTRIES; i=i+1) begin
            match_result_stage1[i] <= (cam_array[i] == match_data);
        end
    end
end

// Stage 2: Result registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        match_data_stage2 <= 0;
        valid_stage2 <= 0;
        match_result_stage2 <= 0;
        match_lines <= 0;
        match_ready <= 0;
    end else begin
        match_data_stage2 <= match_data_stage1;
        valid_stage2 <= valid_stage1;
        match_result_stage2 <= match_result_stage1;
        match_lines <= match_result_stage1;
        match_ready <= valid_stage1;
    end
end

endmodule