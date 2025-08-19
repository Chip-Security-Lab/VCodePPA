//SystemVerilog
// Top-level module
module rom_checksum #(parameter AW=6) (
    input [AW-1:0] addr,
    output [8:0] data
);
    wire [7:0] mem_data;
    wire parity_bit;
    
    // Memory submodule instance
    rom_memory #(
        .AW(AW)
    ) u_rom_memory (
        .addr(addr),
        .data(mem_data)
    );
    
    // Parity generator submodule instance
    parity_generator u_parity_generator (
        .data_in(mem_data),
        .parity_out(parity_bit)
    );
    
    // Combine parity bit with memory data
    assign data = {parity_bit, mem_data};
    
endmodule

// Memory submodule
module rom_memory #(parameter AW=6) (
    input [AW-1:0] addr,
    output [7:0] data
);
    reg [7:0] mem [0:(1<<AW)-1];
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    // Read from memory
    assign data = mem[addr];
    
endmodule

// Parity generator submodule
module parity_generator (
    input [7:0] data_in,
    output parity_out
);
    // Calculate parity (XOR of all bits)
    assign parity_out = ^data_in;
    
endmodule