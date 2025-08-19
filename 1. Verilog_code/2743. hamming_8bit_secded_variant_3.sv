//SystemVerilog
module hamming_8bit_secded(
    input [7:0] data,
    output [12:0] code
);
    // Stage 1: Data path registers
    reg [7:0] data_reg;
    always @(*) begin
        data_reg = data;
    end

    // Stage 2: Parity calculation pipeline
    reg [3:0] parity_reg;
    reg overall_parity_reg;
    
    // Parity calculation logic
    always @(*) begin
        // P0: Check bits 7,5,3,1
        parity_reg[0] = data_reg[7] ^ data_reg[5] ^ data_reg[3] ^ data_reg[1];
        
        // P1: Check bits 6,5,2,1
        parity_reg[1] = data_reg[6] ^ data_reg[5] ^ data_reg[2] ^ data_reg[1];
        
        // P2: Check bits 4,5,6,7
        parity_reg[2] = data_reg[4] ^ data_reg[5] ^ data_reg[6] ^ data_reg[7];
        
        // P3: Overall data parity
        parity_reg[3] = ^data_reg;
        
        // Overall parity for double error detection
        overall_parity_reg = parity_reg[0] ^ parity_reg[1] ^ parity_reg[2] ^ parity_reg[3] ^
                            data_reg[0] ^ data_reg[1] ^ data_reg[2] ^ data_reg[3] ^
                            data_reg[4] ^ data_reg[5] ^ data_reg[6] ^ data_reg[7];
    end

    // Stage 3: Code assembly pipeline
    reg [12:0] code_reg;
    always @(*) begin
        code_reg = {
            overall_parity_reg,    // Bit 12
            data_reg[7:4],         // Bits 11:8
            parity_reg[3],         // Bit 7
            data_reg[3:1],         // Bits 6:4
            parity_reg[2],         // Bit 3
            data_reg[0],           // Bit 2
            parity_reg[1],         // Bit 1
            parity_reg[0]          // Bit 0
        };
    end

    // Final output assignment
    assign code = code_reg;
endmodule