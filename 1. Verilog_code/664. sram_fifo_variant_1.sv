//SystemVerilog
module sram_fifo #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input wr_clk,
    input wr_en,
    input [DW-1:0] din,
    input rd_clk,
    input rd_en,
    output [DW-1:0] dout,
    output full,
    output empty
);

reg [DW-1:0] mem [0:DEPTH-1];
reg [$clog2(DEPTH):0] wr_ptr = 0, rd_ptr = 0;
reg [$clog2(DEPTH):0] wr_ptr_gray = 0, rd_ptr_gray = 0;
reg [$clog2(DEPTH):0] wr_ptr_sync = 0, rd_ptr_sync = 0;

wire wr_inc = wr_en && !full;
wire rd_inc = rd_en && !empty;

// Binary to Gray conversion
function automatic [$clog2(DEPTH):0] bin2gray;
    input [$clog2(DEPTH):0] bin;
    begin
        bin2gray = bin ^ (bin >> 1);
    end
endfunction

// Gray to Binary conversion
function automatic [$clog2(DEPTH):0] gray2bin;
    input [$clog2(DEPTH):0] gray;
    reg [$clog2(DEPTH):0] bin;
    integer i;
    begin
        bin[$clog2(DEPTH)] = gray[$clog2(DEPTH)];
        for(i = $clog2(DEPTH)-1; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        gray2bin = bin;
    end
endfunction

// Write domain
always @(posedge wr_clk) begin
    if (wr_inc) begin
        mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
        wr_ptr <= wr_ptr + 1'b1;
        wr_ptr_gray <= bin2gray(wr_ptr + 1'b1);
    end
    rd_ptr_sync <= rd_ptr_gray;
end

// Read domain
always @(posedge rd_clk) begin
    if (rd_inc) begin
        rd_ptr <= rd_ptr + 1'b1;
        rd_ptr_gray <= bin2gray(rd_ptr + 1'b1);
    end
    wr_ptr_sync <= wr_ptr_gray;
end

// Full/Empty detection using Gray code
wire [$clog2(DEPTH):0] wr_ptr_bin = gray2bin(wr_ptr_sync);
wire [$clog2(DEPTH):0] rd_ptr_bin = gray2bin(rd_ptr_sync);

assign full = (wr_ptr - rd_ptr_bin) == DEPTH;
assign empty = (wr_ptr_bin == rd_ptr);
assign dout = mem[rd_ptr[$clog2(DEPTH)-1:0]];

endmodule