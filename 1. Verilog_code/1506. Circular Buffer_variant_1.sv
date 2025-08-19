//SystemVerilog
// IEEE 1364-2005 Verilog standard
module circular_shift_buffer #(parameter SIZE = 8, WIDTH = 4) (
    input wire clk, reset, write_en,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] buffer [0:SIZE-1];
    reg [$clog2(SIZE)-1:0] read_ptr, write_ptr;
    reg [$clog2(SIZE)-1:0] next_read_ptr, next_write_ptr;
    
    // Pre-calculate next pointer values to reduce critical path
    always @(*) begin
        next_write_ptr = (write_ptr == SIZE-1) ? 0 : write_ptr + 1;
        next_read_ptr = (read_ptr == SIZE-1) ? 0 : read_ptr + 1;
    end
    
    // Separate data path from control path
    always @(posedge clk) begin
        if (reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
            data_out <= 0;
        end else if (write_en) begin
            buffer[write_ptr] <= data_in;
            write_ptr <= next_write_ptr;
            read_ptr <= next_read_ptr;
            data_out <= buffer[next_read_ptr];
        end
    end
endmodule