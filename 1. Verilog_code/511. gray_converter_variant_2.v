module gray_converter(
    input wire clk,
    input wire rst_n,
    input wire [3:0] bin,
    output reg [3:0] gray
);

    // Pipeline registers
    reg [3:0] bin_reg;
    reg [3:0] gray_reg1;
    reg [3:0] gray_reg2;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_reg <= 4'b0;
        end else begin
            bin_reg <= bin;
        end
    end

    // Stage 2: First level gray conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg1 <= 4'b0;
        end else begin
            gray_reg1[3] <= bin_reg[3];
            gray_reg1[2] <= bin_reg[3] ^ bin_reg[2];
            gray_reg1[1] <= bin_reg[2];
            gray_reg1[0] <= bin_reg[1];
        end
    end

    // Stage 3: Second level gray conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg2 <= 4'b0;
        end else begin
            gray_reg2[3:2] <= gray_reg1[3:2];
            gray_reg2[1] <= gray_reg1[2] ^ gray_reg1[1];
            gray_reg2[0] <= gray_reg1[1] ^ bin_reg[0];
        end
    end

    // Stage 4: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray <= 4'b0;
        end else begin
            gray <= gray_reg2;
        end
    end

endmodule