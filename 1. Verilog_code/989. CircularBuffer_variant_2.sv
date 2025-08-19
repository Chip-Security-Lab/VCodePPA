//SystemVerilog
module CircularBuffer #(parameter DEPTH=8, ADDR_WIDTH=3) (
    input wire clk,
    input wire wr_en,
    input wire rd_en,
    input wire data_in,
    output wire data_out
);
    reg [DEPTH-1:0] mem;
    reg [ADDR_WIDTH-1:0] write_pointer, read_pointer;
    reg read_enable_d;
    reg [ADDR_WIDTH-1:0] read_pointer_d;
    reg data_out_reg;

    // Efficient pointer update and memory access
    always @(posedge clk) begin
        // Write operation
        if (wr_en) begin
            mem[write_pointer] <= data_in;
        end

        // Pointer increment logic (optimized)
        write_pointer <= (wr_en) ? ((write_pointer == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : write_pointer + 1'b1) : write_pointer;
        read_pointer  <= (rd_en) ? ((read_pointer  == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : read_pointer  + 1'b1) : read_pointer;

        // Registered delayed read enable and pointer for clean timing
        read_enable_d  <= rd_en;
        read_pointer_d <= read_pointer;

        // Read operation
        if (read_enable_d) begin
            data_out_reg <= mem[read_pointer_d];
        end
    end

    assign data_out = data_out_reg;

endmodule