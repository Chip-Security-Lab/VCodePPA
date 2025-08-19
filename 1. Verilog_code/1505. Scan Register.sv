module scan_register #(parameter WIDTH = 8) (
    input wire scan_clk, scan_rst, scan_en, test_mode,
    input wire scan_in,
    input wire [WIDTH-1:0] data_in,
    output wire scan_out,
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] scan_reg;
    
    always @(posedge scan_clk) begin
        if (scan_rst)
            scan_reg <= 0;
        else if (test_mode && scan_en)
            scan_reg <= {scan_reg[WIDTH-2:0], scan_in};
        else if (!test_mode)
            scan_reg <= data_in;
    end
    
    assign scan_out = scan_reg[WIDTH-1];
    assign data_out = scan_reg;
endmodule