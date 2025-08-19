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
    
    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    
    // Pointer registers
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH-1:0] wr_ptr_next, rd_ptr_next;
    
    // Register input signals to reduce input delay
    reg write_en_r, read_en_r;
    reg [DATA_WIDTH-1:0] data_in_r;
    
    // Count register with reduced critical path
    reg [ADDR_WIDTH:0] count;
    reg [ADDR_WIDTH:0] count_next;
    wire write_valid, read_valid;
    
    // Output status flags with registered logic
    reg empty_pre, full_pre;
    
    // Assign output flags
    assign empty = empty_pre;
    assign full = full_pre;
    
    // Qualify operations
    assign write_valid = write_en_r & ~full_pre;
    assign read_valid = read_en_r & ~empty_pre;
    
    // Input registration stage to reduce input timing path
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            write_en_r <= 1'b0;
            read_en_r <= 1'b0;
            data_in_r <= {DATA_WIDTH{1'b0}};
        end else begin
            write_en_r <= write_en;
            read_en_r <= read_en;
            data_in_r <= data_in;
        end
    end
    
    // Pre-compute next pointer values - moved after input registration
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            wr_ptr_next <= 1'b1;  // Reset to 1 to point to next location
            rd_ptr_next <= 1'b1;  // Reset to 1 to point to next location
        end else begin
            wr_ptr_next <= wr_ptr + 1'b1;
            rd_ptr_next <= rd_ptr + 1'b1;
        end
    end
    
    // Calculate status signals based on registered inputs
    always @(*) begin
        count_next = count;
        
        if (write_valid && !read_valid)
            count_next = count + 1'b1;
        else if (!write_valid && read_valid)
            count_next = count - 1'b1;
    end
    
    // Status computation - moved after input registration to reduce critical path
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            empty_pre <= 1'b1;
            full_pre <= 1'b0;
        end else begin
            empty_pre <= (count_next == 0);
            full_pre <= (count_next == FIFO_DEPTH);
        end
    end
    
    // Main control logic with pipelined operations
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            // Update count
            count <= count_next;
            
            // Write operation with registered inputs
            if (write_valid) begin
                mem[wr_ptr] <= data_in_r;
                wr_ptr <= wr_ptr_next;
            end
            
            // Read operation with registered inputs
            if (read_valid) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr_next;
            end
        end
    end
endmodule