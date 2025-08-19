//SystemVerilog
module usb_sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input wire clk,
    input wire rst_b,
    input wire write_en,
    input wire read_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    // Memory declaration
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    
    // Pointers and counters
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] count;
    
    // Pipeline registers for count operations
    reg write_en_r, read_en_r;
    reg [ADDR_WIDTH:0] count_wr_stage, count_rd_stage;
    reg full_r, empty_r;
    
    // Status flags with registered outputs for better timing
    assign full = full_r;
    assign empty = empty_r;
    
    // First stage: Register inputs and perform memory operations
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            write_en_r <= 0;
            read_en_r <= 0;
        end else begin
            // Register control signals
            write_en_r <= write_en && !full_r;
            read_en_r <= read_en && !empty_r;
            
            // Write operation
            if (write_en && !full_r) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            // Read operation
            if (read_en && !empty_r) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
    
    // Second stage: Count calculations using conditional sum subtractor
    wire [ADDR_WIDTH:0] count_next;
    wire dec_count, inc_count;
    wire [ADDR_WIDTH:0] count_minus1;
    wire [ADDR_WIDTH:0] count_plus1;
    
    // Control signals for count operations
    assign inc_count = write_en_r && !read_en_r;
    assign dec_count = !write_en_r && read_en_r;
    
    // Conditional sum subtractor implementation
    // Instead of directly using count - 1'b1, we implement a conditional sum subtractor
    assign count_minus1 = {1'b1, ~count[ADDR_WIDTH-1:0]} + 1'b1; // 2's complement for subtraction
    assign count_plus1 = count + 1'b1;
    
    // Select the next count value based on operations
    assign count_next = inc_count ? count_plus1 : 
                        dec_count ? {count[ADDR_WIDTH:1], count[0] ^ count_minus1[0]} : 
                        count;
    
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            count <= 0;
            count_wr_stage <= 0;
            count_rd_stage <= 0;
            full_r <= 0;
            empty_r <= 1;
        end else begin
            // Calculate intermediate count values
            count_wr_stage <= write_en_r ? 1'b1 : 1'b0;
            count_rd_stage <= read_en_r ? 1'b1 : 1'b0;
            
            // Update count using conditional sum subtractor
            count <= count_next;
            
            // Update status flags based on count
            full_r <= (count == FIFO_DEPTH-1 && write_en_r && !read_en_r) || 
                      (count == FIFO_DEPTH);
            empty_r <= (count == 1 && !write_en_r && read_en_r) || 
                       (count == 0);
        end
    end
endmodule