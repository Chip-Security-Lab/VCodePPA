module rom_checksum #(parameter AW=6)(
    input [AW-1:0] addr,
    output [8:0] data
);
    reg [7:0] mem [0:(1<<AW)-1];
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    assign data = {^mem[addr], mem[addr]};
endmodule