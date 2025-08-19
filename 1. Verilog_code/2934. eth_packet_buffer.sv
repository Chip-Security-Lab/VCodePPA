module eth_packet_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 12,
    parameter DEPTH = 4096
) (
    input wire clk_write,
    input wire clk_read,
    input wire reset,
    input wire write_en,
    input wire read_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    reg [DATA_WIDTH-1:0] buffer [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] write_ptr, read_ptr;
    reg [ADDR_WIDTH:0] count; // Extra bit for full/empty detection
    
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    assign data_out = buffer[read_ptr];
    
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            write_ptr <= 0;
        end else if (write_en && !full) begin
            buffer[write_ptr] <= data_in;
            write_ptr <= (write_ptr == DEPTH-1) ? 0 : write_ptr + 1;
        end
    end
    
    always @(posedge clk_read or posedge reset) begin
        if (reset) begin
            read_ptr <= 0;
        end else if (read_en && !empty) begin
            read_ptr <= (read_ptr == DEPTH-1) ? 0 : read_ptr + 1;
        end
    end
    
    always @(posedge clk_write or posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if (write_en && !full && (!read_en || empty))
                count <= count + 1;
            else if (read_en && !empty && (!write_en || full))
                count <= count - 1;
        end
    end
endmodule