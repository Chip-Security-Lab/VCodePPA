//SystemVerilog
module BiDir_NAND(
    inout [7:0] bus_a,
    inout [7:0] bus_b,
    input dir,
    output [7:0] result
);

    reg [7:0] bus_a_reg;
    reg [7:0] bus_b_reg;
    reg bus_a_oe;
    reg bus_b_oe;

    // Explicit 2-to-1 multiplexer for result
    wire [7:0] bus_a_int;
    wire [7:0] bus_b_int;
    assign bus_a_int = bus_a;
    assign bus_b_int = bus_b;

    wire [7:0] nand_result;
    assign nand_result = (~bus_a_int) | (~bus_b_int);
    assign result = nand_result;

    // Tri-state buffer control for bus_a
    assign bus_a = bus_a_oe ? bus_a_reg : 8'hzz;
    // Tri-state buffer control for bus_b
    assign bus_b = bus_b_oe ? bus_b_reg : 8'hzz;

    always @(*) begin
        // Explicit 2-to-1 multiplexers for register assignments and output enables
        case (dir)
            1'b1: begin
                bus_a_reg = nand_result;
                bus_a_oe  = 1'b1;
                bus_b_reg = 8'h00;
                bus_b_oe  = 1'b0;
            end
            1'b0: begin
                bus_a_reg = 8'h00;
                bus_a_oe  = 1'b0;
                bus_b_reg = nand_result;
                bus_b_oe  = 1'b1;
            end
            default: begin
                bus_a_reg = 8'h00;
                bus_a_oe  = 1'b0;
                bus_b_reg = 8'h00;
                bus_b_oe  = 1'b0;
            end
        endcase
    end

endmodule