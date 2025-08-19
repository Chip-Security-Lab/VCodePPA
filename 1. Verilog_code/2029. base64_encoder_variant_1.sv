//SystemVerilog
// Top-level Base64 Encoder Module with Structured Pipelined Data Path

module base64_encoder (
    input         clk,
    input         rst_n,
    input  [23:0] data_in,
    output [31:0] encoded_out
);

    // Stage 1: Input Registering
    reg [23:0] data_in_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_reg <= 24'b0;
        else
            data_in_reg <= data_in;
    end

    // Stage 2: Data Grouping (Registering outputs)
    wire [5:0] group0_wire, group1_wire, group2_wire, group3_wire;
    reg  [5:0] group0_reg, group1_reg, group2_reg, group3_reg;

    base64_grouping u_grouping (
        .data_in(data_in_reg),
        .group0(group0_wire),
        .group1(group1_wire),
        .group2(group2_wire),
        .group3(group3_wire)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            group0_reg <= 6'b0;
            group1_reg <= 6'b0;
            group2_reg <= 6'b0;
            group3_reg <= 6'b0;
        end else begin
            group0_reg <= group0_wire;
            group1_reg <= group1_wire;
            group2_reg <= group2_wire;
            group3_reg <= group3_wire;
        end
    end

    // Stage 3: Character Mapping (Registering outputs)
    wire [7:0] char0_wire, char1_wire, char2_wire, char3_wire;
    reg  [7:0] char0_reg, char1_reg, char2_reg, char3_reg;

    base64_charset_map u_map0 (
        .six_bit_in(group0_reg),
        .char_out(char0_wire)
    );

    base64_charset_map u_map1 (
        .six_bit_in(group1_reg),
        .char_out(char1_wire)
    );

    base64_charset_map u_map2 (
        .six_bit_in(group2_reg),
        .char_out(char2_wire)
    );

    base64_charset_map u_map3 (
        .six_bit_in(group3_reg),
        .char_out(char3_wire)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            char0_reg <= 8'b0;
            char1_reg <= 8'b0;
            char2_reg <= 8'b0;
            char3_reg <= 8'b0;
        end else begin
            char0_reg <= char0_wire;
            char1_reg <= char1_wire;
            char2_reg <= char2_wire;
            char3_reg <= char3_wire;
        end
    end

    // Stage 4: Output Registering
    reg [31:0] encoded_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encoded_reg <= 32'b0;
        else
            encoded_reg <= {char0_reg, char1_reg, char2_reg, char3_reg};
    end

    assign encoded_out = encoded_reg;

endmodule

// ----------------------------------------------------------------------
// Data Grouping Submodule for Base64 Encoder
// Splits 24-bit input into four 6-bit groups as per Base64 encoding rules
// ----------------------------------------------------------------------
module base64_grouping (
    input  [23:0] data_in,
    output [5:0]  group0,
    output [5:0]  group1,
    output [5:0]  group2,
    output [5:0]  group3
);

    assign group0 = data_in[23:18];
    assign group1 = data_in[17:12];
    assign group2 = data_in[11:6];
    assign group3 = data_in[5:0];

endmodule

// ----------------------------------------------------------------------
// Character Set Mapping Submodule for Base64 Encoder
// Maps 6-bit group to 8-bit ASCII character (simplified mapping)
// Replace the mapping logic with full Base64 charset if needed
// ----------------------------------------------------------------------
module base64_charset_map (
    input  [5:0] six_bit_in,
    output [7:0] char_out
);

    // Example: Direct mapping (for demonstration, not actual Base64 mapping)
    assign char_out = {2'b00, six_bit_in};

    // For full Base64, replace the above line with a lookup/mapping logic

endmodule