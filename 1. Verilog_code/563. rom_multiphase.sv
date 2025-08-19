module rom_multiphase #(parameter PHASES=4)(
    input clk,
    input [1:0] phase,
    input [5:0] addr,
    output [7:0] data
);
    reg [7:0] mem [0:255];
    
    // Initialize memory with values
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    assign data = mem[{phase, addr}];
endmodule