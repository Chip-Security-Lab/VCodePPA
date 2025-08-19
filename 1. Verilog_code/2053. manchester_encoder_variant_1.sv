//SystemVerilog
module manchester_encoder (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire data_in,
    output reg manchester_out
);

    reg half_bit;
    reg data_in_reg;
    reg manchester_out_next;

    // Internal signals for signed multiplication
    wire signed [7:0] signed_data;
    wire signed [7:0] signed_half_bit;
    wire signed [15:0] mult_result;
    wire signed [7:0] manchester_logic;

    assign signed_data = {7'b0, data_in_reg};     // 8-bit sign-extended input
    assign signed_half_bit = {7'b0, half_bit};    // 8-bit sign-extended half_bit

    // Signed multiplication: (data_in_reg * (~half_bit)) + ((~data_in_reg) * half_bit)
    // This implements manchester encoding logic using signed multiplication
    assign mult_result = (signed_data * (~signed_half_bit + 8'd1)) + ((~signed_data + 8'd1) * signed_half_bit);

    // Extract encoded bit (LSB) and map to logic 0 or 1
    assign manchester_logic = (mult_result[0] == 1'b0) ? 8'd1 : 8'd0;

    // half_bit flip-flop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            half_bit <= 1'b0;
        else if (enable)
            half_bit <= ~half_bit;
    end

    // data_in_reg flip-flop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_reg <= 1'b0;
        else if (enable)
            data_in_reg <= data_in;
    end

    // combinational logic for manchester_out_next using signed multiplication result
    always @(*) begin
        manchester_out_next = manchester_logic[0];
    end

    // manchester_out sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            manchester_out <= 1'b0;
        else if (enable)
            manchester_out <= manchester_out_next;
    end

endmodule