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
    output reg [ENTRIES-1:0] match_lines
);

// Pipeline stage 1: Write and data preparation
reg [DW-1:0] cam_array [0:ENTRIES-1];
reg [DW-1:0] match_data_stage1;
reg [4:0] wr_addr_stage1;
reg we_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        we_stage1 <= 1'b0;
        match_data_stage1 <= {DW{1'b0}};
        wr_addr_stage1 <= 5'b0;
    end else begin
        we_stage1 <= we;
        match_data_stage1 <= match_data;
        wr_addr_stage1 <= wr_addr;
    end
end

always @(posedge clk) begin
    if (we_stage1) cam_array[wr_addr_stage1] <= wr_data;
end

// Pipeline stage 2: Comparison
wire [DW-1:0] diff [0:ENTRIES-1];
reg [ENTRIES-1:0] match_temp_stage2;

genvar j;
generate
    for (j=0; j<ENTRIES; j=j+1) begin : COMPARE_GEN
        assign diff[j] = cam_array[j] - match_data_stage1;
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        match_temp_stage2 <= {ENTRIES{1'b0}};
    end else begin
        for (integer i = 0; i < ENTRIES; i = i + 1) begin
            match_temp_stage2[i] <= ~|diff[i];
        end
    end
end

// Pipeline stage 3: Output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        match_lines <= {ENTRIES{1'b0}};
    end else begin
        match_lines <= match_temp_stage2;
    end
end

endmodule