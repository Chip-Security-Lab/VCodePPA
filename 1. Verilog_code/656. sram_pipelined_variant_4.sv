//SystemVerilog
module sram_pipelined #(
    parameter DW = 64,
    parameter AW = 8
)(
    input clk,
    input rst_n,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] pipe_reg_stage1;
reg [DW-1:0] pipe_reg_stage2;
reg [AW-1:0] addr_stage1;
reg [AW-1:0] addr_stage2;
reg valid_stage1;
reg valid_stage2;
reg we_stage1;
reg we_stage2;
reg [DW-1:0] din_stage1;
reg [DW-1:0] mem_data_stage1;
reg mem_access_valid;

// Stage 1: Address, Write Enable, and Data Pipeline
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 0;
        we_stage1 <= 0;
        valid_stage1 <= 0;
        din_stage1 <= 0;
    end else if (ce) begin
        addr_stage1 <= addr;
        we_stage1 <= we;
        valid_stage1 <= 1;
        din_stage1 <= din;
    end else begin
        valid_stage1 <= 0;
    end
end

// Stage 2: Memory Access Pipeline - Split into two parts
// Part 1: Memory read and write control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage2 <= 0;
        we_stage2 <= 0;
        valid_stage2 <= 0;
        mem_access_valid <= 0;
    end else if (valid_stage1) begin
        addr_stage2 <= addr_stage1;
        we_stage2 <= we_stage1;
        valid_stage2 <= 1;
        mem_access_valid <= 1;
    end else begin
        valid_stage2 <= 0;
        mem_access_valid <= 0;
    end
end

// Part 2: Memory data access
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_data_stage1 <= 0;
        pipe_reg_stage1 <= 0;
    end else if (mem_access_valid) begin
        if (we_stage1) begin
            mem[addr_stage1] <= din_stage1;
            mem_data_stage1 <= din_stage1;
        end else begin
            mem_data_stage1 <= mem[addr_stage1];
        end
        pipe_reg_stage1 <= mem_data_stage1;
    end
end

// Stage 3: Output Pipeline
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
        pipe_reg_stage2 <= 0;
    end else if (valid_stage2) begin
        pipe_reg_stage2 <= pipe_reg_stage1;
        dout <= pipe_reg_stage2;
    end
end

endmodule