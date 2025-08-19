//SystemVerilog
module des_key_scheduler #(parameter KEY_WIDTH = 56, KEY_OUT = 48) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [5:0] round,
    output reg [KEY_OUT-1:0] subkey
);
    // Pipeline stage 1: Key rotation
    reg [KEY_WIDTH-1:0] rotated_key;
    wire [KEY_WIDTH-1:0] round_shifted_key;
    
    // Left circular shift based on round number (PC-1)
    // Single-bit shift or double-bit shift based on round[0]
    assign round_shifted_key = (round[0]) ? {key_in[KEY_WIDTH-2:0], key_in[KEY_WIDTH-1]} :
                                            {key_in[KEY_WIDTH-3:0], key_in[KEY_WIDTH-1:KEY_WIDTH-2]};
    
    // Pipeline stage 2: Complementation datapath
    reg [19:0] middle_section;
    reg [19:0] inverted_bits;
    reg [19:0] comp_section;
    reg [9:0] high_section;
    reg [25:0] low_section;
    
    // Pipeline stage 3: Final subkey formation
    always @(*) begin
        // Stage 1: Capture rotated key
        rotated_key = round_shifted_key;
        
        // Stage 2: Process middle section with two's complement when needed
        low_section = rotated_key[45:20];
        middle_section = rotated_key[19:0];
        high_section = rotated_key[55:46];
        
        // Two's complement calculation path
        inverted_bits = ~middle_section;
        comp_section = (rotated_key[55]) ? (inverted_bits + 1'b1) : middle_section;
        
        // Stage 3: Final subkey composition (PC-2)
        subkey = {low_section, comp_section, high_section};
    end
endmodule