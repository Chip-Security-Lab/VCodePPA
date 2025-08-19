module unsigned_subtractor_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] diff
);

    // Pipeline stage registers
    reg [7:0] a_reg, b_reg;
    reg [3:0] msb_diff_reg, lsb_diff_reg;
    reg [7:0] result_reg;

    // Stage 1: Input sampling and MSB computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            msb_diff_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            msb_diff_reg <= a[7:4] - b[7:4];
        end
    end

    // Stage 2: LSB computation and result assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lsb_diff_reg <= 4'b0;
            result_reg <= 8'b0;
        end else begin
            lsb_diff_reg <= a_reg[3:0] - b_reg[3:0];
            result_reg <= {msb_diff_reg, lsb_diff_reg};
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 8'b0;
        end else begin
            diff <= result_reg;
        end
    end

endmodule