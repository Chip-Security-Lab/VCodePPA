//SystemVerilog
// IEEE 1364-2005 Verilog
module AsyncFIFOShift #(parameter DEPTH=8, AW=$clog2(DEPTH)) (
    input wr_clk, rd_clk,
    input wr_en, rd_en,
    input din,
    output reg dout
);
    reg [DEPTH-1:0] mem = 0;
    reg [AW:0] wr_ptr = 0, rd_ptr = 0;
    reg [AW-1:0] rd_addr;
    
    // Write domain logic optimization
    always @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_ptr[AW-1:0]] <= din;
            wr_ptr <= wr_ptr + 1'b1; // Use literal for better synthesis
        end
    end

    // Read domain logic optimization with improved timing
    always @(posedge rd_clk) begin
        // Use registered address for memory access
        rd_addr <= rd_ptr[AW-1:0];
        
        // Update read pointer on enable
        if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1; // Use literal for better synthesis
        end
        
        // Output registered data from memory
        dout <= mem[rd_addr];
    end
endmodule