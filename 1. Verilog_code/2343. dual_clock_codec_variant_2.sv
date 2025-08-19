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
    
    // FIFO memory and pointers
    reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    
    // Write pointer and its buffers with load balancing
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_logic; // Dedicated for logic
    reg [ADDR_WIDTH:0] wr_ptr_sync;  // Dedicated for synchronization
    reg [ADDR_WIDTH:0] wr_ptr_buf1, wr_ptr_buf2;
    
    // Read pointer and its buffers with load balancing
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] rd_ptr_logic; // Dedicated for logic
    reg [ADDR_WIDTH:0] rd_ptr_sync;  // Dedicated for synchronization
    reg [ADDR_WIDTH:0] rd_ptr_buf1, rd_ptr_buf2;
    
    // Address decode signals with buffers
    reg [ADDR_WIDTH-1:0] wr_addr, wr_addr_buf;
    reg [ADDR_WIDTH-1:0] rd_addr, rd_addr_buf;
    
    // Buffered data signals
    reg [DATA_WIDTH-1:0] data_in_buf;
    
    // Fifo read data with fanout buffering
    reg [DATA_WIDTH-1:0] fifo_rd_data;
    reg [DATA_WIDTH-1:0] fifo_rd_data_rgb; // Buffer for RGB extraction
    
    // Extract RGB components with buffering
    reg [4:0] r_component, g_component, b_component;
    
    // Buffer the write pointer for different logic paths
    always @(posedge src_clk) begin
        if (rst) begin
            wr_ptr_logic <= 0;
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_logic <= wr_ptr;
            wr_ptr_sync <= wr_ptr;
        end
    end
    
    // Write address decode logic with buffering
    always @(*) begin
        wr_addr = wr_ptr_logic[ADDR_WIDTH-1:0];
    end
    
    always @(posedge src_clk) begin
        wr_addr_buf <= wr_addr;
        data_in_buf <= data_in;
    end
    
    // Write logic with buffered signals
    always @(posedge src_clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            fifo[wr_addr_buf] <= data_in_buf;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Buffer the write pointer for full/empty logic
    always @(posedge src_clk) begin
        wr_ptr_buf1 <= wr_ptr_sync;
    end
    
    // Buffer the read pointer for different logic paths
    always @(posedge dst_clk) begin
        if (rst) begin
            rd_ptr_logic <= 0;
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_logic <= rd_ptr;
            rd_ptr_sync <= rd_ptr;
        end
    end
    
    // Read address decode logic with buffering
    always @(*) begin
        rd_addr = rd_ptr_logic[ADDR_WIDTH-1:0];
    end
    
    always @(posedge dst_clk) begin
        rd_addr_buf <= rd_addr;
    end
    
    // Buffered read data with fanout distribution
    always @(posedge dst_clk) begin
        if (!empty) begin
            fifo_rd_data <= fifo[rd_addr_buf];
        end
    end
    
    // Second stage buffer for fifo_rd_data to distribute high fanout
    always @(posedge dst_clk) begin
        fifo_rd_data_rgb <= fifo_rd_data;
    end
    
    // Extract RGB components with registers to distribute load
    always @(posedge dst_clk) begin
        r_component <= fifo_rd_data_rgb[23:19];
        g_component <= fifo_rd_data_rgb[15:10];
        b_component <= fifo_rd_data_rgb[7:3];
    end
    
    // Read logic with distributed load
    always @(posedge dst_clk) begin
        if (rst) begin
            rd_ptr <= 0;
            data_out <= 0;
        end else if (rd_en && !empty) begin
            data_out <= {r_component, g_component, b_component};
            rd_ptr <= rd_ptr + 1;
        end
    end
    
    // Buffer the read pointer for full/empty logic
    always @(posedge dst_clk) begin
        rd_ptr_buf1 <= rd_ptr_sync;
    end
    
    // Synchronize pointers across clock domains (2-stage synchronization)
    always @(posedge src_clk) begin
        if (rst) rd_ptr_buf2 <= 0;
        else rd_ptr_buf2 <= rd_ptr_buf1;
    end
    
    always @(posedge dst_clk) begin
        if (rst) wr_ptr_buf2 <= 0;
        else wr_ptr_buf2 <= wr_ptr_buf1;
    end
    
    // Status flags with synchronized pointers
    assign full = (wr_ptr_logic[ADDR_WIDTH-1:0] == rd_ptr_buf2[ADDR_WIDTH-1:0]) && 
                 (wr_ptr_logic[ADDR_WIDTH] != rd_ptr_buf2[ADDR_WIDTH]);
    assign empty = (wr_ptr_buf2 == rd_ptr_logic);
    
endmodule