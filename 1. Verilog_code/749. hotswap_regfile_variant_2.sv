//SystemVerilog
module hotswap_regfile #(
    parameter DW = 28,
    parameter AW = 5,
    parameter DEFAULT_VAL = 32'hDEADBEEF
)(
    input clk,
    input rst_n,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] din,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] dout,
    input [31:0] reg_enable
);

// Pipeline stage 1: Address and control signal registration
reg [AW-1:0] wr_addr_stage1;
reg [AW-1:0] rd_addr_stage1;
reg wr_en_stage1;
reg [31:0] reg_enable_stage1;
reg [DW-1:0] din_stage1;

// Pipeline stage 2: Memory access
reg [DW-1:0] mem [0:(1<<AW)-1];
wire wr_en_gated_stage2 = wr_en_stage1 && reg_enable_stage1[wr_addr_stage1];
reg [DW-1:0] mem_data_stage2;

// Pipeline stage 3: Output selection
reg [DW-1:0] dout_stage3;

// Stage 1: Register inputs
always @(posedge clk) begin
    if (!rst_n) begin
        wr_addr_stage1 <= 0;
        rd_addr_stage1 <= 0;
        wr_en_stage1 <= 0;
        reg_enable_stage1 <= 0;
        din_stage1 <= 0;
    end else begin
        wr_addr_stage1 <= wr_addr;
        rd_addr_stage1 <= rd_addr;
        wr_en_stage1 <= wr_en;
        reg_enable_stage1 <= reg_enable;
        din_stage1 <= din;
    end
end

// Stage 2: Memory access
always @(posedge clk) begin
    if (!rst_n) begin
        integer i;
        i = 0;
        while (i < (1<<AW)) begin
            mem[i] <= DEFAULT_VAL;
            i = i + 1;
        end
        mem_data_stage2 <= DEFAULT_VAL;
    end else begin
        if (wr_en_gated_stage2) begin
            mem[wr_addr_stage1] <= din_stage1;
        end
        mem_data_stage2 <= mem[rd_addr_stage1];
    end
end

// Stage 3: Output selection
always @(posedge clk) begin
    if (!rst_n) begin
        dout_stage3 <= DEFAULT_VAL;
    end else begin
        dout_stage3 <= reg_enable_stage1[rd_addr_stage1] ? mem_data_stage2 : DEFAULT_VAL;
    end
end

assign dout = dout_stage3;

endmodule