//SystemVerilog
module rom_multiphase #(parameter PHASES=4)(
    input clk,
    input [1:0] phase,
    input [5:0] addr,
    output [7:0] data
);
    reg [7:0] mem [0:255];
    wire [7:0] calculated_addr;
    wire [7:0] phase_extended;
    
    // Initialize memory with values
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    // Extend phase to 8 bits
    assign phase_extended = {6'b000000, phase};
    
    // Carry-lookahead adder to calculate address
    carry_lookahead_adder cla_inst (
        .a(phase_extended),
        .b({addr, 2'b00}),
        .cin(1'b0),
        .sum(calculated_addr),
        .cout()
    );
    
    assign data = mem[calculated_addr];
endmodule

// 8-bit Carry-lookahead adder
module carry_lookahead_adder(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] p; // Propagate
    wire [7:0] g; // Generate
    wire [8:0] c; // Carry
    
    // Calculate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Set initial carry-in
    assign c[0] = cin;
    
    // Calculate carries using lookahead logic
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Calculate sum
    assign sum = p ^ c[7:0];
    
    // Set carry-out
    assign cout = c[8];
endmodule