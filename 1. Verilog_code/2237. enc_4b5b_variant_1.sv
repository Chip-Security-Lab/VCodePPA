//SystemVerilog
// Top-level module for 4B/5B encoder/decoder
module enc_4b5b (
    input wire clk, rst_n,
    input wire encode_mode, // 1=encode, 0=decode
    input wire [3:0] data_in,
    input wire [4:0] code_in,
    output wire [4:0] code_out,
    output wire [3:0] data_out,
    output wire valid_out, code_err
);
    // Internal signals for connecting submodules
    wire [4:0] encoder_code_out;
    wire [3:0] decoder_data_out;
    wire decoder_valid_out, decoder_code_err;

    // Encoder submodule instance
    encoder_4b5b u_encoder (
        .clk(clk),
        .rst_n(rst_n),
        .enable(encode_mode),
        .data_in(data_in),
        .code_out(encoder_code_out)
    );

    // Decoder submodule instance
    decoder_5b4b u_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .enable(!encode_mode),
        .code_in(code_in),
        .data_out(decoder_data_out),
        .valid_out(decoder_valid_out),
        .code_err(decoder_code_err)
    );

    // Output multiplexer based on encode_mode
    output_mux u_output_mux (
        .encode_mode(encode_mode),
        .encoder_code_out(encoder_code_out),
        .decoder_data_out(decoder_data_out),
        .decoder_valid_out(decoder_valid_out),
        .decoder_code_err(decoder_code_err),
        .code_out(code_out),
        .data_out(data_out),
        .valid_out(valid_out),
        .code_err(code_err)
    );

endmodule

// Encoder submodule - handles 4b to 5b conversion
module encoder_4b5b (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [3:0] data_in,
    output reg [4:0] code_out
);
    // 4B/5B encoding lookup table
    (* ram_style = "distributed" *) reg [4:0] enc_lut [0:15];
    
    // Initialize LUT with encoding values
    initial begin
        enc_lut[0] = 5'b11110; // 0 -> 0x1E
        enc_lut[1] = 5'b01001; // 1 -> 0x09
        enc_lut[2] = 5'b10100; // 2 -> 0x14
        enc_lut[3] = 5'b10101; // 3 -> 0x15
        enc_lut[4] = 5'b01010; // 4 -> 0x0A
        enc_lut[5] = 5'b01011; // 5 -> 0x0B
        enc_lut[6] = 5'b01110; // 6 -> 0x0E
        enc_lut[7] = 5'b01111; // 7 -> 0x0F
        enc_lut[8] = 5'b10010; // 8 -> 0x12
        enc_lut[9] = 5'b10011; // 9 -> 0x13
        enc_lut[10] = 5'b10110; // A -> 0x16
        enc_lut[11] = 5'b10111; // B -> 0x17
        enc_lut[12] = 5'b11010; // C -> 0x1A
        enc_lut[13] = 5'b11011; // D -> 0x1B
        enc_lut[14] = 5'b11100; // E -> 0x1C
        enc_lut[15] = 5'b11101; // F -> 0x1D
    end

    // Encoding process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out <= 5'b0;
        end else if (enable) begin
            code_out <= enc_lut[data_in];
        end
    end
endmodule

// Decoder submodule - handles 5b to 4b conversion
module decoder_5b4b (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [4:0] code_in,
    output reg [3:0] data_out,
    output reg valid_out,
    output reg code_err
);
    // Decoding process with reverse lookup implementation
    reg valid_code;
    reg [3:0] dec_data;

    // Decode logic - using a case statement for clearer implementation
    always @(*) begin
        valid_code = 1'b1;
        case (code_in)
            5'b11110: dec_data = 4'h0;
            5'b01001: dec_data = 4'h1;
            5'b10100: dec_data = 4'h2;
            5'b10101: dec_data = 4'h3;
            5'b01010: dec_data = 4'h4;
            5'b01011: dec_data = 4'h5;
            5'b01110: dec_data = 4'h6;
            5'b01111: dec_data = 4'h7;
            5'b10010: dec_data = 4'h8;
            5'b10011: dec_data = 4'h9;
            5'b10110: dec_data = 4'hA;
            5'b10111: dec_data = 4'hB;
            5'b11010: dec_data = 4'hC;
            5'b11011: dec_data = 4'hD;
            5'b11100: dec_data = 4'hE;
            5'b11101: dec_data = 4'hF;
            default: begin
                dec_data = 4'h0;
                valid_code = 1'b0;
            end
        endcase
    end

    // Registered outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 4'b0;
            valid_out <= 1'b0;
            code_err <= 1'b0;
        end else if (enable) begin
            data_out <= dec_data;
            valid_out <= valid_code;
            code_err <= !valid_code;
        end
    end
endmodule

// Output multiplexer - selects appropriate outputs based on mode
module output_mux (
    input wire encode_mode,
    input wire [4:0] encoder_code_out,
    input wire [3:0] decoder_data_out,
    input wire decoder_valid_out,
    input wire decoder_code_err,
    output reg [4:0] code_out,
    output reg [3:0] data_out,
    output reg valid_out,
    output reg code_err
);
    // Combinational multiplexing logic
    always @(*) begin
        if (encode_mode) begin
            // Encoding mode outputs
            code_out = encoder_code_out;
            data_out = 4'b0;  // Not used in encode mode
            valid_out = 1'b1; // Always valid in encode mode
            code_err = 1'b0;  // No errors in encode mode
        end else begin
            // Decoding mode outputs
            code_out = 5'b0;  // Not used in decode mode
            data_out = decoder_data_out;
            valid_out = decoder_valid_out;
            code_err = decoder_code_err;
        end
    end
endmodule