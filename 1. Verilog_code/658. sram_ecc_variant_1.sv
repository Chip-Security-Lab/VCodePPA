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

(* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

// Buffer registers for write path
reg wr_en_buf;
reg [AW-1:0] wr_addr_buf;
reg [DW-1:0] wr_data_buf;

// Buffer registers for read path
reg rd_en_buf;
reg [AW-1:0] rd_addr_buf;
reg [DW-1:0] rd_data_buf;

// Write path buffering
always @(posedge wr_clk) begin
    wr_en_buf <= wr_en;
    wr_addr_buf <= wr_addr;
    wr_data_buf <= wr_data;
end

// Write operation with buffered signals
always @(posedge wr_clk) begin
    if (wr_en_buf) begin
        mem[wr_addr_buf] <= wr_data_buf;
    end
end

// Read path buffering
always @(posedge rd_clk) begin
    rd_en_buf <= rd_en;
    rd_addr_buf <= rd_addr;
end

// Read operation with buffered signals
always @(posedge rd_clk) begin
    if (rd_en_buf) begin
        rd_data_buf <= mem[rd_addr_buf];
    end
    rd_data <= rd_data_buf;
end

endmodule