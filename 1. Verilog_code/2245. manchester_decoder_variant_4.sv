//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: manchester_decoder_top.v
// Description: Manchester decoder top module with forward retiming optimization
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////

module manchester_decoder_top (
    input  wire clk,         // System clock
    input  wire rst_n,       // Active low reset
    input  wire encoded,     // Manchester encoded input
    output wire decoded,     // Decoded output bit
    output reg  clk_recovered // Recovered clock signal
);

    // Internal signals for interconnection
    wire edge_detected;
    wire prev_bit_value;
    reg  encoded_reg;        // Register for input encoded signal

    // Register the input data to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encoded_reg <= 1'b0;
        else
            encoded_reg <= encoded;
    end

    // Edge detection submodule
    edge_detector u_edge_detector (
        .clk         (clk),
        .rst_n       (rst_n),
        .encoded     (encoded_reg),
        .prev_bit    (prev_bit_value),
        .edge_detected(edge_detected)
    );

    // Previous bit storage submodule
    bit_storage u_bit_storage (
        .clk         (clk),
        .rst_n       (rst_n),
        .encoded     (encoded_reg),
        .prev_bit    (prev_bit_value)
    );

    // Bit decoder submodule
    bit_decoder u_bit_decoder (
        .encoded     (encoded_reg),
        .prev_bit    (prev_bit_value),
        .decoded     (decoded)
    );

    // Register the recovered clock for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_recovered <= 1'b0;
        else
            clk_recovered <= edge_detected;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Edge detection submodule
///////////////////////////////////////////////////////////////////////////////

module edge_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire encoded,
    input  wire prev_bit,
    output wire edge_detected
);

    // Edge detected when current bit differs from previous bit
    assign edge_detected = (encoded != prev_bit);

endmodule

///////////////////////////////////////////////////////////////////////////////
// Bit storage submodule
///////////////////////////////////////////////////////////////////////////////

module bit_storage (
    input  wire clk,
    input  wire rst_n,
    input  wire encoded,
    output reg  prev_bit
);

    // Store previous bit value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            prev_bit <= 1'b0;
        else
            prev_bit <= encoded;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Bit decoder submodule
///////////////////////////////////////////////////////////////////////////////

module bit_decoder (
    input  wire encoded,
    input  wire prev_bit,
    output wire decoded
);

    // Decode the manchester encoded data
    assign decoded = (encoded ^ prev_bit);

endmodule