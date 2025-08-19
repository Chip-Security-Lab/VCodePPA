//SystemVerilog
module rom_parity #(parameter BITS=12)(
    input wire clk,
    input wire [7:0] addr,
    output reg [BITS-1:0] data
);
    // Memory declaration with improved naming
    reg [BITS-2:0] rom_storage [0:255];
    
    // Pipeline registers
    reg [7:0] addr_stage1;
    reg [BITS-2:0] data_stage1;
    reg [BITS-2:0] data_stage2;
    reg parity_stage2;
    
    // Example initialization
    initial begin
        // Set specific example values for synthesis
        rom_storage[0] = 11'b10101010101;
        rom_storage[1] = 11'b01010101010;
        // $readmemb("parity_data.bin", rom_storage); // Used in simulation
    end
    
    // Combined pipeline stages - all stages have the same clock trigger
    always @(posedge clk) begin
        // Pipeline stage 1: Address registration and ROM read
        addr_stage1 <= addr;
        data_stage1 <= rom_storage[addr];
        
        // Pipeline stage 2: Parity calculation and data forwarding
        data_stage2 <= data_stage1;
        parity_stage2 <= ^data_stage1;
        
        // Pipeline stage 3: Final data assembly
        data <= {parity_stage2, data_stage2};
    end
endmodule