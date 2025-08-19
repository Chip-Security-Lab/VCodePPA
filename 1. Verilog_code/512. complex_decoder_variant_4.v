module complex_decoder(
    input wire clk, rst_n,
    input wire a, b, c,
    output reg [7:0] dec
);

    // Input registration stage
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

    // AB combination stage
    reg [1:0] ab_comb;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ab_comb <= 2'b00;
        else
            ab_comb <= {a_reg, b_reg};
    end

    // Decode stage
    reg [7:0] decode_stage;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_stage <= 8'h00;
        else begin
            case (ab_comb)
                2'b00: decode_stage <= c_reg ? 8'h02 : 8'h01;
                2'b01: decode_stage <= c_reg ? 8'h08 : 8'h04;
                2'b10: decode_stage <= c_reg ? 8'h20 : 8'h10;
                2'b11: decode_stage <= c_reg ? 8'h80 : 8'h40;
            endcase
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dec <= 8'h00;
        else
            dec <= decode_stage;
    end

endmodule