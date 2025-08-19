//SystemVerilog
module present_light (
    input clk, enc_dec,
    input [63:0] plaintext,
    output reg [63:0] ciphertext
);
    reg [79:0] key_reg;
    reg [63:0] plaintext_reg;
    wire [63:0] key_temp;
    
    // Register plaintext at input to reduce input-to-register delay
    always @(posedge clk) begin
        plaintext_reg <= plaintext;
    end
    
    // Key rotation logic - kept in register path
    always @(posedge clk) begin
        key_reg <= {key_reg[18:0], key_reg[79:76]};
    end
    
    // Directly use key_reg instead of buffering through multiple stages
    assign key_temp = key_reg[63:0];
    
    // Final output stage with XOR operation 
    always @(posedge clk) begin
        ciphertext <= plaintext_reg ^ key_temp;
        // Simplified sBoxLayer and pLayer omitted
    end
endmodule