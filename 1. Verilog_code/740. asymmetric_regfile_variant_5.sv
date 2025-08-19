//SystemVerilog
module asymmetric_regfile #(
    parameter WR_DW = 64,
    parameter RD_DW = 32
)(
    input clk,
    input rst_n,
    input wr_en,
    input [2:0] wr_addr,
    input [WR_DW-1:0] din,
    input [3:0] rd_addr,
    output reg [RD_DW-1:0] dout,
    output reg valid_out
);

// Pipeline stage 1 registers
reg [WR_DW-1:0] mem [0:7];
reg [3:0] rd_addr_stage1;
reg wr_en_stage1;
reg [2:0] wr_addr_stage1;
reg [WR_DW-1:0] din_stage1;
reg valid_stage1;

// Pipeline stage 2 registers
reg [WR_DW-1:0] mem_data_stage2;
reg sel_high_stage2;
reg valid_stage2;

// Borrow bit for subtraction
reg borrow;
reg [3:0] diff; // 4-bit difference

// Stage 1: Memory access
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
        rd_addr_stage1 <= 4'b0;
        wr_en_stage1 <= 1'b0;
        wr_addr_stage1 <= 3'b0;
        din_stage1 <= {WR_DW{1'b0}};
    end else begin
        valid_stage1 <= 1'b1;
        rd_addr_stage1 <= rd_addr;
        wr_en_stage1 <= wr_en;
        wr_addr_stage1 <= wr_addr;
        din_stage1 <= din;
        
        if (wr_en) begin
            mem[wr_addr] <= din;
        end
    end
end

// Stage 2: Data selection and borrow subtraction
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage2 <= 1'b0;
        mem_data_stage2 <= {WR_DW{1'b0}};
        sel_high_stage2 <= 1'b0;
        borrow <= 1'b0;
        diff <= 4'b0;
    end else begin
        valid_stage2 <= valid_stage1;
        mem_data_stage2 <= mem[rd_addr_stage1[2:0]];
        sel_high_stage2 <= rd_addr_stage1[3];
        
        // Borrow subtraction logic for 4-bit subtraction
        {borrow, diff} <= {1'b0, mem_data_stage2[3:0]} - {1'b0, din_stage1[3:0]};
    end
end

// Stage 3: Output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out <= 1'b0;
        dout <= {RD_DW{1'b0}};
    end else begin
        valid_out <= valid_stage2;
        dout <= sel_high_stage2 ? 
            {mem_data_stage2[WR_DW-1:RD_DW], diff} : 
            diff;
    end
end

endmodule