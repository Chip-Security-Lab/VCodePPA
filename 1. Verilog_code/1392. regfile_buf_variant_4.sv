//SystemVerilog
// Top-level module
module regfile_buf #(
    parameter DW = 32
)(
    input wire clk,
    input wire [1:0] wr_sel, rd_sel,
    input wire wr_en,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout
);
    // Internal register storage
    reg [DW-1:0] reg_data[0:3];
    
    // Direct output assignment with combinational multiplexer
    assign dout = reg_data[rd_sel];
    
    // Optimized write logic with one-hot encoding
    wire [3:0] write_enable;
    assign write_enable = wr_en ? (4'b0001 << wr_sel) : 4'b0000;
    
    // Register update logic
    always @(posedge clk) begin
        if (write_enable[0]) reg_data[0] <= din;
        if (write_enable[1]) reg_data[1] <= din;
        if (write_enable[2]) reg_data[2] <= din;
        if (write_enable[3]) reg_data[3] <= din;
    end
    
endmodule