//SystemVerilog
module dual_port_buffer (
    input wire clk,
    input wire [31:0] write_data,
    input wire write_valid,
    output reg write_ready,
    output reg [31:0] read_data,
    output reg read_valid,
    input wire read_ready
);
    reg [31:0] buffer;
    reg buffer_valid;
    
    // Write handshake logic with forward retiming
    // Directly update the buffer when data is valid and ready
    always @(posedge clk) begin
        if (write_valid && (!buffer_valid || (read_valid && read_ready))) begin
            buffer <= write_data;
            buffer_valid <= 1'b1;
        end else if (read_valid && read_ready) begin
            buffer_valid <= 1'b0;
        end
    end
    
    // Read handshake logic - optimized to reduce latency
    always @(posedge clk) begin
        if (buffer_valid && (!read_valid || (read_valid && read_ready)))
            read_valid <= buffer_valid && !read_ready;
        else if (read_valid && read_ready)
            read_valid <= 1'b0;
    end
    
    // Data transfer - moved forward to reduce path delay
    always @(posedge clk) begin
        if (buffer_valid)
            read_data <= buffer;
    end
    
    // Write ready logic - computed combinationally to reduce latency
    // We're ready when buffer is empty or being read
    always @(*) begin
        write_ready = !buffer_valid || (read_valid && read_ready);
    end
endmodule