//SystemVerilog
module multi_io_ctrl (
    input clk, mode_sel,
    input [7:0] data_in,
    output reg scl, sda, spi_cs
);
    // Pipeline registers to break combinational paths
    reg mode_sel_reg;
    reg [7:0] data_in_reg;
    reg scl_reg, sda_reg, spi_cs_reg;
    
    // First pipeline stage - register inputs
    always @(posedge clk) begin
        mode_sel_reg <= mode_sel;
        data_in_reg <= data_in;
        scl_reg <= scl;
        sda_reg <= sda;
        spi_cs_reg <= spi_cs;
    end
    
    // Second pipeline stage - perform logic with registered inputs
    always @(posedge clk) begin
        scl <= mode_sel_reg ? ~scl_reg : scl_reg;
        sda <= mode_sel_reg ? data_in_reg[7] : sda_reg;
        spi_cs <= mode_sel_reg ? spi_cs_reg : data_in_reg[0];
    end
endmodule