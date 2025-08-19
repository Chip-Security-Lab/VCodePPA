//SystemVerilog
module circular_shift_buffer #(parameter SIZE = 8, WIDTH = 4) (
    input wire clk, reset, write_en,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    reg [$clog2(SIZE)-1:0] read_ptr, write_ptr;
    reg [WIDTH-1:0] buffer [0:SIZE-1];
    reg [WIDTH-1:0] data_out_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
            data_out_reg <= 0;
        end else if (write_en) begin
            buffer[write_ptr] <= data_in;
            write_ptr <= (write_ptr + 1) % SIZE;
            read_ptr <= (read_ptr + 1) % SIZE;
            data_out_reg <= buffer[read_ptr];
        end
    end
    
    assign data_out = data_out_reg;
endmodule