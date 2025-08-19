//SystemVerilog
module present_light_top (
    input wire clk,
    input wire enc_dec,
    input wire [63:0] plaintext,
    output wire [63:0] ciphertext
);
    // Internal signals
    wire [79:0] updated_key;
    wire [63:0] processed_plaintext;
    wire [79:0] key_reg;
    wire [63:0] plaintext_reg;

    // Instantiate key scheduler module
    key_scheduler key_unit (
        .clk(clk),
        .key_in(key_reg),
        .key_out(updated_key)
    );

    // Instantiate data register module
    data_register data_unit (
        .clk(clk),
        .plaintext_in(plaintext),
        .plaintext_out(plaintext_reg)
    );

    // Instantiate key register module
    key_register key_reg_unit (
        .clk(clk),
        .key_in(updated_key),
        .key_out(key_reg)
    );

    // Instantiate encryption module
    encryption_unit enc_unit (
        .clk(clk),
        .enc_dec(enc_dec),
        .data_in(plaintext_reg),
        .key(key_reg[63:0]),
        .data_out(ciphertext)
    );

endmodule

// Key scheduler module
module key_scheduler (
    input wire clk,
    input wire [79:0] key_in,
    output wire [79:0] key_out
);
    // Key scheduling logic
    assign key_out = {key_in[18:0], key_in[79:76]};
endmodule

// Data register module
module data_register (
    input wire clk,
    input wire [63:0] plaintext_in,
    output reg [63:0] plaintext_out
);
    // Register plaintext input
    always @(posedge clk) begin
        plaintext_out <= plaintext_in;
    end
endmodule

// Key register module
module key_register (
    input wire clk,
    input wire [79:0] key_in,
    output reg [79:0] key_out
);
    // Initialize the key register
    initial begin
        key_out = 80'h0;
    end

    // Update key register
    always @(posedge clk) begin
        key_out <= key_in;
    end
endmodule

// Encryption module
module encryption_unit (
    input wire clk,
    input wire enc_dec,
    input wire [63:0] data_in,
    input wire [63:0] key,
    output reg [63:0] data_out
);
    // Perform XOR operation for AddRoundKey
    always @(posedge clk) begin
        data_out <= data_in ^ key;
        // Simplified sBoxLayer and pLayer omitted
    end
endmodule