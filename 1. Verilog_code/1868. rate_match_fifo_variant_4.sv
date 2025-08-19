//SystemVerilog
module rate_match_fifo #(parameter DATA_W=8, DEPTH=8) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output reg [DATA_W-1:0] dout
);
reg [DATA_W-1:0] mem [0:DEPTH-1];
reg [$clog2(DEPTH):0] wr_ptr = 0, rd_ptr = 0;
reg [$clog2(DEPTH)-1:0] rd_addr_reg;
reg empty_reg;
reg full_reg;

// Write pointer logic
always @(posedge wr_clk or posedge rst) 
    if (rst) wr_ptr <= 0;
    else if (wr_en && !full_reg) begin
        mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
        wr_ptr <= wr_ptr + 1;
    end

// Read pointer logic
always @(posedge rd_clk or posedge rst) 
    if (rst) begin
        rd_ptr <= 0;
        rd_addr_reg <= 0;
    end
    else if (rd_en && !empty_reg) begin
        rd_ptr <= rd_ptr + 1;
        rd_addr_reg <= rd_ptr[$clog2(DEPTH)-1:0] + 1;
    end
    else begin
        rd_addr_reg <= rd_ptr[$clog2(DEPTH)-1:0];
    end

// Full/Empty status registers
always @(posedge wr_clk or posedge rst)
    if (rst) full_reg <= 0;
    else full_reg <= ((wr_ptr + 1'b1) - rd_ptr) >= DEPTH;

always @(posedge rd_clk or posedge rst)
    if (rst) empty_reg <= 1;
    else empty_reg <= (wr_ptr == rd_ptr + (rd_en && !empty_reg ? 1'b1 : 1'b0));

// Data output register
always @(posedge rd_clk or posedge rst)
    if (rst) dout <= 0;
    else if (rd_en && !empty_reg)
        dout <= mem[rd_addr_reg];

assign full = full_reg;
assign empty = empty_reg;
endmodule