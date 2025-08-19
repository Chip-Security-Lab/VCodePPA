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
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    
    // Pre-registered input signals (retimed to input)
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg wr_en_reg;
    
    // Input signal registration (forward retiming)
    always @(posedge src_clk) begin
        if (rst) begin
            data_in_reg <= 0;
            wr_en_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            wr_en_reg <= wr_en;
        end
    end
    
    // Write logic (input clock domain) - now uses registered inputs
    always @(posedge src_clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en_reg && !full) begin
            fifo[wr_ptr[ADDR_WIDTH-1:0]] <= data_in_reg;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    
    // Pre-registered signals for read side
    reg rd_en_reg;
    reg [ADDR_WIDTH-1:0] rd_addr;
    
    // Register read enable and calculate read address
    always @(posedge dst_clk) begin
        if (rst) begin
            rd_en_reg <= 0;
            rd_addr <= 0;
        end else begin
            rd_en_reg <= rd_en && !empty;
            rd_addr <= rd_ptr[ADDR_WIDTH-1:0];
        end
    end
    
    // Pre-compute RGB conversion in a separate stage
    reg [15:0] rgb_conversion;
    always @(posedge dst_clk) begin
        // RGB565 format conversion: RRRRR_GGGGGG_BBBBB
        rgb_conversion <= {
            fifo[rd_addr][23:19],  // 5 bits of R
            fifo[rd_addr][15:10],  // 6 bits of G
            fifo[rd_addr][7:3]     // 5 bits of B
        };
    end
    
    // Read logic (output clock domain) with registered RGB conversion
    always @(posedge dst_clk) begin
        if (rst) begin
            rd_ptr <= 0;
            data_out <= 0;
        end else if (rd_en_reg) begin
            data_out <= rgb_conversion;
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    // Optimized full and empty comparison logic
    wire [ADDR_WIDTH:0] ptr_diff = wr_ptr - rd_ptr;
    
    // Full when all but MSB bits are 0 and MSB is 1
    assign full = (ptr_diff[ADDR_WIDTH-1:0] == {ADDR_WIDTH{1'b0}}) && 
                  (ptr_diff[ADDR_WIDTH] == 1'b1);
                  
    // Empty when all bits are 0
    assign empty = (ptr_diff == {(ADDR_WIDTH+1){1'b0}});
endmodule