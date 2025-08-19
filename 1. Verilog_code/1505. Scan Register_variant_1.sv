//SystemVerilog
module scan_register #(parameter WIDTH = 8) (
    input wire scan_clk, scan_rst, scan_en, test_mode,
    input wire scan_in,
    input wire [WIDTH-1:0] data_in,
    output wire scan_out,
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] scan_reg;
    reg [WIDTH-1:0] scan_reg_buf;
    wire next_scan_value = test_mode & scan_en;
    wire [WIDTH-1:0] next_reg_value;
    
    assign next_reg_value = scan_rst ? {WIDTH{1'b0}} :
                           next_scan_value ? {scan_reg[WIDTH-2:0], scan_in} : 
                           data_in;
    
    always @(posedge scan_clk) begin
        scan_reg <= next_reg_value;
        scan_reg_buf <= scan_reg;
    end
    
    assign scan_out = scan_reg_buf[WIDTH-1];
    assign data_out = scan_reg_buf;
endmodule