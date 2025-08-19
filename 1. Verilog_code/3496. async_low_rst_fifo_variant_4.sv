//SystemVerilog
//IEEE 1364-2005
module async_low_rst_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en, rd_en,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    output wire empty, full
);
    // Internal signals
    wire [DATA_WIDTH-1:0] fifo_data_out;
    wire [1:0] wr_ptr, rd_ptr;
    wire [2:0] fifo_count;
    wire write_valid, read_valid;
    
    // Control logic submodule
    fifo_controller #(
        .DEPTH(DEPTH)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .write_valid(write_valid),
        .read_valid(read_valid),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .fifo_count(fifo_count)
    );
    
    // Memory submodule
    fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) memory_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(write_valid),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .din(din),
        .dout(fifo_data_out)
    );
    
    // Output register submodule
    fifo_output_reg #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_inst (
        .clk(clk),
        .rst_n(rst_n),
        .read_valid(read_valid),
        .data_in(fifo_data_out),
        .dout(dout)
    );
    
endmodule

module fifo_controller #(
    parameter DEPTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en, rd_en,
    output wire full, empty,
    output wire write_valid, read_valid,
    output reg [1:0] wr_ptr, rd_ptr,
    output reg [2:0] fifo_count
);
    // Status flags
    assign empty = (fifo_count == 0);
    assign full = (fifo_count == DEPTH);
    
    // Valid operation signals
    assign write_valid = wr_en && !full;
    assign read_valid = rd_en && !empty;
    
    // Look-ahead borrow signals for 3-bit subtractor
    wire [2:0] borrow;
    wire [2:0] diff;
    
    // Generate borrow signals for look-ahead borrow subtractor
    assign borrow[0] = read_valid;
    assign borrow[1] = fifo_count[0] & borrow[0];
    assign borrow[2] = fifo_count[1] & borrow[1];
    
    // Calculate difference using look-ahead borrow subtractor
    assign diff[0] = fifo_count[0] ^ borrow[0];
    assign diff[1] = fifo_count[1] ^ borrow[1];
    assign diff[2] = fifo_count[2] ^ borrow[2];
    
    // Pointer and count management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
        end else begin
            // Update write pointer
            if (write_valid) begin
                wr_ptr <= wr_ptr + 1;
            end
            
            // Update read pointer
            if (read_valid) begin
                rd_ptr <= rd_ptr + 1;
            end
            
            // Update FIFO count based on operations
            case ({write_valid, read_valid})
                2'b10: fifo_count <= fifo_count + 1; // Only write
                2'b01: fifo_count <= diff;          // Only read, using look-ahead borrow subtractor
                2'b11: fifo_count <= fifo_count;     // Both (stays the same)
                default: fifo_count <= fifo_count;   // No operation
            endcase
        end
    end
endmodule

module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [1:0] wr_ptr, rd_ptr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);
    // Memory storage
    reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];
    
    // Write operation
    always @(posedge clk) begin
        if (wr_en) begin
            fifo_mem[wr_ptr] <= din;
        end
    end
    
    // Read operation (combinational)
    assign dout = fifo_mem[rd_ptr];
    
endmodule

module fifo_output_reg #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire read_valid,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] dout
);
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
        end else if (read_valid) begin
            dout <= data_in;
        end
    end
endmodule