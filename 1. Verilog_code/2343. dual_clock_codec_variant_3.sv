//SystemVerilog
module dual_clock_codec #(
    parameter DATA_WIDTH = 24,
    parameter FIFO_DEPTH = 4
) (
    input src_clk, dst_clk, rst,
    input [DATA_WIDTH-1:0] data_in,
    input wr_en, rd_en,
    output reg [15:0] data_out,
    output full, empty
);
    // Constants and local parameters
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    
    // FIFO memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    
    // Write domain registers and signals
    reg [PTR_WIDTH-1:0] wr_ptr_src;
    reg [PTR_WIDTH-1:0] rd_ptr_sync_to_src;
    wire wr_full;
    
    // Write datapath pipeline registers
    reg wr_en_pipe1, wr_en_pipe2;
    reg [DATA_WIDTH-1:0] wr_data_pipe1, wr_data_pipe2;
    reg [ADDR_WIDTH-1:0] wr_addr_pipe1, wr_addr_pipe2;
    reg wr_full_pipe1, wr_full_pipe2;
    
    // Read domain registers and signals
    reg [PTR_WIDTH-1:0] rd_ptr_dst;
    reg [PTR_WIDTH-1:0] wr_ptr_sync_to_dst;
    wire rd_empty;
    
    // Read datapath pipeline registers
    reg rd_en_pipe1, rd_en_pipe2, rd_en_pipe3;
    reg rd_empty_pipe1, rd_empty_pipe2, rd_empty_pipe3;
    reg [ADDR_WIDTH-1:0] rd_addr_pipe1, rd_addr_pipe2;
    reg [DATA_WIDTH-1:0] rd_data_pipe1, rd_data_pipe2;
    
    // Color processing pipeline registers
    reg [7:0] r_data_raw, g_data_raw;
    reg [4:0] r_data_conv, r_data_final;
    reg [5:0] g_data_conv, g_data_final;
    reg [4:0] b_data_conv, b_data_final;
    
    // Synchronizers for clock domain crossing (CDC)
    reg [PTR_WIDTH-1:0] rd_ptr_gray_dst, rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] wr_ptr_gray_src, wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    
    // Binary to Gray code conversion functions
    function [PTR_WIDTH-1:0] bin2gray(input [PTR_WIDTH-1:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction
    
    // Gray to Binary code conversion functions
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
    
    // Clock domain crossing synchronization - Write to Read domain
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
            wr_ptr_sync_to_dst <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray_src;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
            wr_ptr_sync_to_dst <= gray2bin(wr_ptr_gray_sync2);
        end
    end
    
    // Clock domain crossing synchronization - Read to Write domain
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
            rd_ptr_sync_to_src <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray_dst;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
            rd_ptr_sync_to_src <= gray2bin(rd_ptr_gray_sync2);
        end
    end
    
    // Status flags with proper synchronization
    assign wr_full = ((wr_ptr_src[ADDR_WIDTH-1:0] == rd_ptr_sync_to_src[ADDR_WIDTH-1:0]) && 
                    (wr_ptr_src[ADDR_WIDTH] != rd_ptr_sync_to_src[ADDR_WIDTH]));
    assign rd_empty = (wr_ptr_sync_to_dst == rd_ptr_dst);
    
    // Connect module outputs
    assign full = wr_full;
    assign empty = rd_empty;
    
    //------------------------------------------
    // Write Domain Logic (src_clk domain)
    //------------------------------------------
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_src <= 0;
            wr_ptr_gray_src <= 0;
            
            // Reset write pipeline registers
            wr_en_pipe1 <= 0;
            wr_en_pipe2 <= 0;
            wr_data_pipe1 <= 0;
            wr_data_pipe2 <= 0;
            wr_addr_pipe1 <= 0;
            wr_addr_pipe2 <= 0;
            wr_full_pipe1 <= 0;
            wr_full_pipe2 <= 0;
        end else begin
            // Stage 1: Input Registration
            wr_en_pipe1 <= wr_en;
            wr_data_pipe1 <= data_in;
            wr_addr_pipe1 <= wr_ptr_src[ADDR_WIDTH-1:0];
            wr_full_pipe1 <= wr_full;
            
            // Stage 2: Memory Write Preparation
            wr_en_pipe2 <= wr_en_pipe1;
            wr_data_pipe2 <= wr_data_pipe1;
            wr_addr_pipe2 <= wr_addr_pipe1;
            wr_full_pipe2 <= wr_full_pipe1;
            
            // Stage 3: Memory Write and Pointer Update
            if (wr_en_pipe2 && !wr_full_pipe2) begin
                fifo_mem[wr_addr_pipe2] <= wr_data_pipe2;
                wr_ptr_src <= wr_ptr_src + 1'b1;
                wr_ptr_gray_src <= bin2gray(wr_ptr_src + 1'b1);
            end else begin
                wr_ptr_gray_src <= bin2gray(wr_ptr_src);
            end
        end
    end
    
    //------------------------------------------
    // Read Domain Logic (dst_clk domain)
    //------------------------------------------
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_dst <= 0;
            rd_ptr_gray_dst <= 0;
            
            // Reset read control pipeline registers
            rd_en_pipe1 <= 0;
            rd_en_pipe2 <= 0;
            rd_en_pipe3 <= 0;
            rd_empty_pipe1 <= 1;
            rd_empty_pipe2 <= 1;
            rd_empty_pipe3 <= 1;
            rd_addr_pipe1 <= 0;
            rd_addr_pipe2 <= 0;
            
            // Reset read data pipeline registers
            rd_data_pipe1 <= 0;
            rd_data_pipe2 <= 0;
            
            // Reset color processing pipeline
            r_data_raw <= 0;
            g_data_raw <= 0;
            r_data_conv <= 0;
            g_data_conv <= 0;
            b_data_conv <= 0;
            r_data_final <= 0;
            g_data_final <= 0;
            b_data_final <= 0;
            
            // Reset output
            data_out <= 0;
        end else begin
            // Stage 1: Control Logic Registration
            rd_en_pipe1 <= rd_en;
            rd_empty_pipe1 <= rd_empty;
            rd_addr_pipe1 <= rd_ptr_dst[ADDR_WIDTH-1:0];
            
            // Stage 2: Memory Read
            rd_en_pipe2 <= rd_en_pipe1;
            rd_empty_pipe2 <= rd_empty_pipe1;
            rd_addr_pipe2 <= rd_addr_pipe1;
            
            if (rd_en_pipe1 && !rd_empty_pipe1) begin
                rd_data_pipe1 <= fifo_mem[rd_addr_pipe1];
            end
            
            // Stage 3: Initial Color Component Extraction
            rd_en_pipe3 <= rd_en_pipe2;
            rd_empty_pipe3 <= rd_empty_pipe2;
            rd_data_pipe2 <= rd_data_pipe1;
            
            // Extract raw color components
            r_data_raw <= rd_data_pipe1[23:16];
            g_data_raw <= rd_data_pipe1[15:8];
            
            // Stage 4: Color Format Conversion
            r_data_conv <= r_data_raw[7:3];
            g_data_conv <= g_data_raw[7:2];
            b_data_conv <= rd_data_pipe2[7:3];  // Blue component from the next stage
            
            // Stage 5: Output Preparation
            r_data_final <= r_data_conv;
            g_data_final <= g_data_conv;
            b_data_final <= b_data_conv;
            
            // Update read pointer when valid read operation completes
            if (rd_en_pipe3 && !rd_empty_pipe3) begin
                rd_ptr_dst <= rd_ptr_dst + 1'b1;
                rd_ptr_gray_dst <= bin2gray(rd_ptr_dst + 1'b1);
            end else begin
                rd_ptr_gray_dst <= bin2gray(rd_ptr_dst);
            end
            
            // Stage 6: Final Output Formation
            data_out <= {r_data_final, g_data_final, b_data_final};
        end
    end
endmodule