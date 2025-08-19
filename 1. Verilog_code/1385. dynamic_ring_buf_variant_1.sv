//SystemVerilog
module dynamic_ring_buf #(
    parameter MAX_DEPTH = 16,
    parameter DW = 8
) (
    input  wire            clk,
    input  wire            rst_n,
    input  wire [3:0]      depth_set,
    input  wire            wr_en,
    input  wire            rd_en,
    input  wire [DW-1:0]   din,
    output reg  [DW-1:0]   dout,
    output wire            full,
    output wire            empty
);
    
    // Memory definition
    reg [DW-1:0] mem[MAX_DEPTH-1:0];
    
    // Pipeline stage registers - more descriptive naming
    // Stage 1: Input Registration
    reg            wr_req_s1;         // Write request registered
    reg            rd_req_s1;         // Read request registered
    reg [DW-1:0]   wr_data_s1;        // Data to be written - stage 1
    reg [3:0]      buf_depth;         // Buffer depth configuration register
    reg            wr_valid_s1;       // Write valid flag - stage 1
    reg            rd_valid_s1;       // Read valid flag - stage 1
    
    // Stage 2: Address Generation
    reg            wr_req_s2;         // Write request - stage 2
    reg            rd_req_s2;         // Read request - stage 2
    reg [DW-1:0]   wr_data_s2;        // Data to be written - stage 2
    reg            wr_valid_s2;       // Write valid flag - stage 2
    reg            rd_valid_s2;       // Read valid flag - stage 2
    reg [3:0]      wr_ptr_s2;         // Write pointer - stage 2
    reg [3:0]      rd_ptr_s2;         // Read pointer - stage 2
    
    // Counter and pointer management
    reg [3:0]      wr_ptr;            // Write pointer
    reg [3:0]      rd_ptr;            // Read pointer
    reg [3:0]      entry_count;       // Number of entries in buffer
    reg [3:0]      entry_count_s2;    // Buffered count for stage 2
    
    // Depth configuration logic with clear limit
    wire [3:0] depth_limit = (depth_set > 0 && depth_set < MAX_DEPTH) ? depth_set : MAX_DEPTH;
    
    // Status flags - centralized calculations
    assign full = (entry_count == buf_depth);
    assign empty = (entry_count == 0);
    
    // =========================================================================
    // Stage 1: Input Registration and Validation
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_req_s1   <= 1'b0;
            rd_req_s1   <= 1'b0;
            wr_data_s1  <= {DW{1'b0}};
            buf_depth   <= 4'd0;
            wr_valid_s1 <= 1'b0;
            rd_valid_s1 <= 1'b0;
        end 
        else begin
            // Register inputs with clear names
            wr_req_s1   <= wr_en;
            rd_req_s1   <= rd_en;
            wr_data_s1  <= din;
            buf_depth   <= depth_limit;
            
            // Calculate operation validity based on current buffer state
            wr_valid_s1 <= wr_en && !full;   // Write is valid if buffer not full
            rd_valid_s1 <= rd_en && !empty;  // Read is valid if buffer not empty
        end
    end
    
    // =========================================================================
    // Stage 2: Address Generation and Operation Preparation
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_req_s2    <= 1'b0;
            rd_req_s2    <= 1'b0;
            wr_data_s2   <= {DW{1'b0}};
            wr_valid_s2  <= 1'b0;
            rd_valid_s2  <= 1'b0;
            wr_ptr_s2    <= 4'd0;
            rd_ptr_s2    <= 4'd0;
            entry_count_s2 <= 4'd0;
        end 
        else begin
            // Forward pipeline signals
            wr_req_s2    <= wr_req_s1;
            rd_req_s2    <= rd_req_s1;
            wr_data_s2   <= wr_data_s1;
            wr_valid_s2  <= wr_valid_s1;
            rd_valid_s2  <= rd_valid_s1;
            
            // Capture current pointers for operation
            wr_ptr_s2    <= wr_ptr;
            rd_ptr_s2    <= rd_ptr;
            entry_count_s2 <= entry_count;
        end
    end
    
    // =========================================================================
    // Stage 3: Memory Access and Pointer Update
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr      <= 4'd0;
            rd_ptr      <= 4'd0;
            entry_count <= 4'd0;
            dout        <= {DW{1'b0}};
        end 
        else begin
            // Memory operation and pointer updates based on operation type
            case ({wr_valid_s2, rd_valid_s2})
                2'b10: begin  // Write only operation
                    // Execute memory write
                    mem[wr_ptr_s2] <= wr_data_s2;
                    
                    // Update write pointer with circular buffer wraparound
                    wr_ptr <= (wr_ptr_s2 == buf_depth - 1) ? 4'd0 : wr_ptr_s2 + 1'b1;
                    
                    // Increment entry count
                    entry_count <= entry_count_s2 + 1'b1;
                end
                
                2'b01: begin  // Read only operation
                    // Execute memory read
                    dout <= mem[rd_ptr_s2];
                    
                    // Update read pointer with circular buffer wraparound
                    rd_ptr <= (rd_ptr_s2 == buf_depth - 1) ? 4'd0 : rd_ptr_s2 + 1'b1;
                    
                    // Decrement entry count
                    entry_count <= entry_count_s2 - 1'b1;
                end
                
                2'b11: begin  // Simultaneous read and write
                    // Execute both operations
                    mem[wr_ptr_s2] <= wr_data_s2;
                    dout <= mem[rd_ptr_s2];
                    
                    // Update both pointers
                    wr_ptr <= (wr_ptr_s2 == buf_depth - 1) ? 4'd0 : wr_ptr_s2 + 1'b1;
                    rd_ptr <= (rd_ptr_s2 == buf_depth - 1) ? 4'd0 : rd_ptr_s2 + 1'b1;
                    
                    // Count remains unchanged during simultaneous operation
                    entry_count <= entry_count_s2;
                end
                
                default: begin  // No operation (2'b00)
                    // Maintain current state
                    wr_ptr <= wr_ptr_s2;
                    rd_ptr <= rd_ptr_s2;
                    entry_count <= entry_count_s2;
                end
            endcase
        end
    end
    
endmodule