module Sub6(
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b, 
    input wire en,
    output reg [7:0] res
);

    // Pipeline stage 1: Split operands
    reg [3:0] a_high_r, a_low_r;
    reg [3:0] b_high_r, b_low_r;
    reg en_r1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_high_r <= 4'b0;
            a_low_r <= 4'b0;
            b_high_r <= 4'b0;
            b_low_r <= 4'b0;
            en_r1 <= 1'b0;
        end else begin
            a_high_r <= a[7:4];
            a_low_r <= a[3:0];
            b_high_r <= b[7:4];
            b_low_r <= b[3:0];
            en_r1 <= en;
        end
    end

    // Pipeline stage 2: Compute differences
    reg [3:0] diff_low_r;
    reg [4:0] carry_r;
    reg en_r2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_low_r <= 4'b0;
            carry_r <= 5'b0;
            en_r2 <= 1'b0;
        end else begin
            diff_low_r <= a_low_r - b_low_r;
            carry_r <= (a_low_r < b_low_r) ? 5'b1 : 5'b0;
            en_r2 <= en_r1;
        end
    end

    // Pipeline stage 3: Final computation and output
    reg [3:0] diff_high_r;
    reg en_r3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_high_r <= 4'b0;
            en_r3 <= 1'b0;
        end else begin
            diff_high_r <= a_high_r - b_high_r - carry_r[0];
            en_r3 <= en_r2;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'b0;
        end else begin
            res <= en_r3 ? {diff_high_r, diff_low_r} : 8'b0;
        end
    end

endmodule