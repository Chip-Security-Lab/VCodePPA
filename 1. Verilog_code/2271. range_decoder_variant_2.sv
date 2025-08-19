//SystemVerilog
module range_decoder(
    input [7:0] addr,
    output reg rom_sel,
    output reg ram_sel,
    output reg io_sel,
    output reg error
);
    // Define address range parameter for better readability
    localparam ROM_UPPER = 8'h40;
    localparam RAM_UPPER = 8'hC0;
    localparam IO_UPPER = 8'hFF;
    
    // Selection logic using standard case with condition flags
    always @(*) begin
        // Default values (important to prevent latches)
        rom_sel = 1'b0;
        ram_sel = 1'b0;
        io_sel = 1'b0;
        error = 1'b0;
        
        // Use condition flags for range checking
        case (1'b1)
            (addr < ROM_UPPER): begin
                rom_sel = 1'b1;
            end
            (addr >= ROM_UPPER) && (addr < RAM_UPPER): begin
                ram_sel = 1'b1;
            end
            (addr >= RAM_UPPER) && (addr <= IO_UPPER): begin
                io_sel = 1'b1;
            end
            default: begin
                error = 1'b1;
            end
        endcase
    end
endmodule