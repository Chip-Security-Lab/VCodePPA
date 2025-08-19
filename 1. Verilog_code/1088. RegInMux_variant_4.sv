//SystemVerilog

module RegInMux #(parameter DW=8) (
    input clk,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output [DW-1:0] dout
);
    reg [3:0][DW-1:0] reg_din;
    always @(posedge clk) reg_din <= din;
    assign dout = reg_din[sel];
endmodule

module BorrowSubtractor4 (
    input  [3:0] minuend,
    input  [3:0] subtrahend,
    output [3:0] difference,
    output       borrow_out
);
    reg [4:0] lut_diff [0:255];
    reg [4:0] lut_entry;
    wire [7:0] lut_addr;
    reg lut_initialized = 1'b0;
    integer i, j;
    
    assign lut_addr = {minuend, subtrahend};

    // LUT Initialization
    always @(*) begin
        if (!lut_initialized) begin
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    {lut_diff[{i[3:0], j[3:0]}][4], lut_diff[{i[3:0], j[3:0]}][3:0]} = { (i < j), (i - j) & 4'hF };
                end
            end
            lut_initialized = 1'b1;
        end
    end

    // Read from LUT
    always @(*) begin
        lut_entry = lut_diff[lut_addr];
    end

    assign difference = lut_entry[3:0];
    assign borrow_out = lut_entry[4];
endmodule