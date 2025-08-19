module complex_decoder(
    input wire clk,
    input wire rst_n,
    input wire a, b, c,
    output reg [7:0] dec
);

    // Input registration
    reg a_reg, b_reg, c_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            c_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
        end
    end

    // Partial decoding logic - split into two always blocks
    reg [1:0] ab_dec;
    always @(*) begin
        case({a_reg, b_reg})
            2'b00: ab_dec = 2'b00;
            2'b01: ab_dec = 2'b01;
            2'b10: ab_dec = 2'b10;
            2'b11: ab_dec = 2'b11;
            default: ab_dec = 2'b00;
        endcase
    end

    // Intermediate registration
    reg [1:0] ab_dec_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_dec_reg <= 2'b00;
        end else begin
            ab_dec_reg <= ab_dec;
        end
    end

    // Final decoding logic - split into two always blocks
    reg [3:0] partial_dec;
    always @(*) begin
        case(ab_dec_reg)
            2'b00: partial_dec = 4'b0001;
            2'b01: partial_dec = 4'b0010;
            2'b10: partial_dec = 4'b0100;
            2'b11: partial_dec = 4'b1000;
            default: partial_dec = 4'b0000;
        endcase
    end

    // Output generation
    reg [7:0] dec_comb;
    always @(*) begin
        case({partial_dec, c_reg})
            5'b0001_0: dec_comb = 8'b00000001;
            5'b0001_1: dec_comb = 8'b00000010;
            5'b0010_0: dec_comb = 8'b00000100;
            5'b0010_1: dec_comb = 8'b00001000;
            5'b0100_0: dec_comb = 8'b00010000;
            5'b0100_1: dec_comb = 8'b00100000;
            5'b1000_0: dec_comb = 8'b01000000;
            5'b1000_1: dec_comb = 8'b10000000;
            default: dec_comb = 8'b00000000;
        endcase
    end

    // Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec <= 8'h00;
        end else begin
            dec <= dec_comb;
        end
    end

endmodule