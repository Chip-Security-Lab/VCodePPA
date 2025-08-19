//SystemVerilog
// IEEE 1364-2005
module arith_shifter #(parameter WIDTH = 8) (
    input wire clk, rst, shift_en,
    input wire [WIDTH-1:0] data_in,
    input wire [2:0] shift_amt,
    output reg [WIDTH-1:0] result
);
    reg [WIDTH-1:0] data_in_reg;
    reg [2:0] shift_amt_reg;
    reg shift_en_reg;
    
    // Register inputs first
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= 0;
            shift_amt_reg <= 0;
            shift_en_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            shift_amt_reg <= shift_amt;
            shift_en_reg <= shift_en;
        end
    end
    
    // Perform arithmetic shift operation in the next cycle
    always @(posedge clk) begin
        if (rst)
            result <= 0;
        else if (shift_en_reg)
            result <= $signed(data_in_reg) >>> shift_amt_reg;
    end
endmodule