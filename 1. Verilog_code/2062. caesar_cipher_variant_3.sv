//SystemVerilog
module caesar_cipher #(parameter SHIFT = 3, CHARSET = 26) (
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  char_in,
    output reg  [7:0]  cipher_out
);

// ================================
// Pipeline Stage 1: Input Capture & Character Classification
// ================================
reg  [7:0]  stage1_char_in;
reg         stage1_is_lowercase;

always @(posedge clk) begin
    if (enable) begin
        stage1_char_in      <= char_in;
        stage1_is_lowercase <= (char_in >= 8'h61) && (char_in <= 8'h7A);
    end
end

// ================================
// Pipeline Stage 2: Offset Calculation
// ================================
reg [7:0] stage2_char_offset;
reg [7:0] stage2_char_in;
reg       stage2_is_lowercase;

always @(posedge clk) begin
    if (enable) begin
        stage2_char_in      <= stage1_char_in;
        stage2_is_lowercase <= stage1_is_lowercase;
        stage2_char_offset  <= (stage1_is_lowercase) ? (stage1_char_in - 8'h61) : 8'h0;
    end
end

// ================================
// Pipeline Stage 3: Shift and Output Calculation
// ================================
reg [7:0] stage3_shifted_char;
reg [7:0] stage3_char_in;
reg       stage3_is_lowercase;

always @(posedge clk) begin
    if (enable) begin
        stage3_char_in      <= stage2_char_in;
        stage3_is_lowercase <= stage2_is_lowercase;
        stage3_shifted_char <= (((stage2_char_offset + SHIFT) % CHARSET) + 8'h61);
    end
end

// ================================
// Pipeline Stage 4: Output Register (Flattened Control Flow)
// ================================
always @(posedge clk) begin
    if (enable && stage3_is_lowercase) begin
        cipher_out <= stage3_shifted_char;
    end else if (enable && !stage3_is_lowercase) begin
        cipher_out <= stage3_char_in;
    end
end

endmodule