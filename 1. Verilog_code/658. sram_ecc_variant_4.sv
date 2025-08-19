//SystemVerilog
module sram_dual_clock #(
    parameter DW = 16,
    parameter AW = 6
)(
    input wr_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    
    input rd_clk,
    input rd_en,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data
);

// Use block RAM primitive for better PPA
(* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

// Write pipeline stage 1: Register inputs
reg wr_en_stage1;
reg [AW-1:0] wr_addr_stage1;
reg [DW-1:0] wr_data_stage1;

// Write pipeline stage 2: Memory write
reg wr_en_stage2;
reg [AW-1:0] wr_addr_stage2;
reg [DW-1:0] wr_data_stage2;

// Read pipeline stage 1: Register inputs
reg rd_en_stage1;
reg [AW-1:0] rd_addr_stage1;

// Read pipeline stage 2: Memory read
reg rd_en_stage2;
reg [AW-1:0] rd_addr_stage2;

// Write pipeline stage 1
always @(posedge wr_clk) begin
    wr_en_stage1 <= wr_en;
    wr_addr_stage1 <= wr_addr;
    wr_data_stage1 <= wr_data;
end

// Write pipeline stage 2
always @(posedge wr_clk) begin
    wr_en_stage2 <= wr_en_stage1;
    wr_addr_stage2 <= wr_addr_stage1;
    wr_data_stage2 <= wr_data_stage1;
    
    if (wr_en_stage2) begin
        mem[wr_addr_stage2] <= wr_data_stage2;
    end
end

// Read pipeline stage 1
always @(posedge rd_clk) begin
    rd_en_stage1 <= rd_en;
    rd_addr_stage1 <= rd_addr;
end

// Read pipeline stage 2
always @(posedge rd_clk) begin
    rd_en_stage2 <= rd_en_stage1;
    rd_addr_stage2 <= rd_addr_stage1;
    
    if (rd_en_stage2) begin
        rd_data <= mem[rd_addr_stage2];
    end
end

endmodule