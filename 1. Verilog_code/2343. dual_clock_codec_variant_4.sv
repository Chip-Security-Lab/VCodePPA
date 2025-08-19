//SystemVerilog
///////////////////////////////////////////////////////////////////////////
// Module: dual_clock_codec
// File: dual_clock_codec.v
// Description: Dual-clock domain FIFO with RGB data conversion
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////
module dual_clock_codec #(
    parameter DATA_WIDTH = 24,
    parameter FIFO_DEPTH = 4
) (
    // Source clock domain
    input                      src_clk,
    input                      wr_en,
    input  [DATA_WIDTH-1:0]    data_in,
    output                     full,
    
    // Destination clock domain
    input                      dst_clk,
    input                      rd_en,
    output [15:0]              data_out,
    output                     empty,
    
    // Shared reset
    input                      rst
);

    // Local parameters for enhanced readability
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    
    // FIFO storage elements
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    
    // Write domain signals
    reg [PTR_WIDTH-1:0] wr_ptr_bin;
    wire [ADDR_WIDTH-1:0] wr_addr;
    
    // Read domain signals
    reg [PTR_WIDTH-1:0] rd_ptr_bin;
    wire [ADDR_WIDTH-1:0] rd_addr;
    
    // Cross-domain synchronized pointers
    reg [PTR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    // Pipeline registers for RGB conversion - Redesigned for retiming
    reg [DATA_WIDTH-1:0] fifo_data_reg;
    reg rd_valid;
    
    // Retimed registers - Pre-conversion registers
    reg [4:0] red_bits;     // 5 bits for red
    reg [5:0] green_bits;   // 6 bits for green 
    reg [4:0] blue_bits;    // 5 bits for blue
    
    // Output registers
    reg [15:0] data_out_reg;
    
    // Binary to Gray conversion functions
    function [PTR_WIDTH-1:0] bin2gray(input [PTR_WIDTH-1:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction
    
    function [PTR_WIDTH-1:0] gray2bin(input [PTR_WIDTH-1:0] gray);
        integer i;
        reg [PTR_WIDTH-1:0] bin;
        begin
            bin = gray;
            for (i = 1; i < PTR_WIDTH; i = i + 1)
                bin = bin ^ (gray >> i);
            gray2bin = bin;
        end
    endfunction

    // Address extraction
    assign wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];
    assign rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];
    
    // Final output assignment (moved from register to continuous assignment)
    assign data_out = data_out_reg;

    //-------------------------------------------------------------------
    // Source Clock Domain Logic (Write Path)
    //-------------------------------------------------------------------
    always @(posedge src_clk) begin
        if (rst) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            // Store data in FIFO memory
            fifo_mem[wr_addr] <= data_in;
            
            // Update write pointer
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end
    
    // Synchronize read pointer to write domain
    always @(posedge src_clk) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    //-------------------------------------------------------------------
    // Destination Clock Domain Logic (Read Path) - Optimized with Retiming
    //-------------------------------------------------------------------
    // Stage 1: Read pointer management and data fetch
    always @(posedge dst_clk) begin
        if (rst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            rd_valid <= 1'b0;
        end else if (rd_en && !empty) begin
            // Read data from FIFO
            fifo_data_reg <= fifo_mem[rd_addr];
            
            // Update read pointer
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
            rd_valid <= 1'b1;
        end else begin
            rd_valid <= 1'b0;
        end
    end
    
    // Stage 2: Pre-computation of RGB components (moved before final combination)
    always @(posedge dst_clk) begin
        if (rst) begin
            red_bits <= 5'h0;
            green_bits <= 6'h0;
            blue_bits <= 5'h0;
        end else if (rd_valid) begin
            // Extract and register individual color components
            red_bits <= fifo_data_reg[23:19];    // 5 bits Red
            green_bits <= fifo_data_reg[15:10];  // 6 bits Green
            blue_bits <= fifo_data_reg[7:3];     // 5 bits Blue
        end
    end
    
    // Stage 3: Combine the pre-computed components (final output stage)
    always @(posedge dst_clk) begin
        if (rst) begin
            data_out_reg <= 16'h0000;
        end else begin
            // Combine the pre-registered color components
            data_out_reg <= {red_bits, green_bits, blue_bits};
        end
    end
    
    // Synchronize write pointer to read domain
    always @(posedge dst_clk) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    //-------------------------------------------------------------------
    // FIFO Status Logic
    //-------------------------------------------------------------------
    // Compute synchronized pointers for status flags
    wire [PTR_WIDTH-1:0] wr_ptr_sync = gray2bin(wr_ptr_gray_sync2);
    wire [PTR_WIDTH-1:0] rd_ptr_sync = gray2bin(rd_ptr_gray_sync2);
    
    // Full and Empty flags
    assign full = (wr_ptr_bin[ADDR_WIDTH-1:0] == rd_ptr_sync[ADDR_WIDTH-1:0]) && 
                 (wr_ptr_bin[ADDR_WIDTH] != rd_ptr_sync[ADDR_WIDTH]);
                 
    assign empty = (rd_ptr_bin == wr_ptr_sync);

endmodule