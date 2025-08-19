//SystemVerilog
module BiDir_NAND(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    // Compute NAND operation once to avoid redundancy
    wire [7:0] nand_result;
    assign nand_result = ~(bus_a & bus_b);

    // Drive buses based on direction control using explicit multiplexer structure
    reg [7:0] bus_a_out, bus_b_out;
    
    // Multiplexer for bus_a output
    always @(*) begin
        case(dir)
            1'b1: bus_a_out = nand_result;
            1'b0: bus_a_out = 8'hzz;
            default: bus_a_out = 8'hzz;
        endcase
    end
    
    // Multiplexer for bus_b output
    always @(*) begin
        case(dir)
            1'b1: bus_b_out = 8'hzz;
            1'b0: bus_b_out = nand_result;
            default: bus_b_out = 8'hzz;
        endcase
    end
    
    // Connect reg outputs to inout ports
    assign bus_a = bus_a_out;
    assign bus_b = bus_b_out;
    
    // Provide result regardless of direction
    assign result = nand_result;
endmodule