module complex_decoder(
    input wire clk,
    input wire rst_n,
    input wire a, b, c,
    output reg [7:0] dec
);

    // Pipeline stage 1: Input selection
    reg [2:0] sel_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_reg <= 3'b000;
        else
            sel_reg <= {a, b, c};
    end

    // Pipeline stage 2: Decode logic
    reg [7:0] decode_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_reg <= 8'b00000001;
        else
            decode_reg <= 8'b1 << sel_reg;
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dec <= 8'b00000001;
        else
            dec <= decode_reg;
    end

endmodule