module subtractor_16bit_pipelined (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg valid_out,
    output reg [15:0] diff
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline stage 1: Input registers
    reg [15:0] a_stage1;
    reg [15:0] b_stage1;
    
    // Pipeline stage 2: Partial results using two's complement addition
    reg [7:0] diff_low_stage2;
    reg [7:0] diff_high_stage2;
    
    // Pipeline stage 3: Final result
    reg [15:0] diff_stage3;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 16'b0;
            b_stage1 <= 16'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Parallel two's complement addition for lower and upper bytes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_low_stage2 <= 8'b0;
            diff_high_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Two's complement addition: a - b = a + (-b) = a + (~b + 1)
            diff_low_stage2 <= a_stage1[7:0] + (~b_stage1[7:0] + 1'b1);
            diff_high_stage2 <= a_stage1[15:8] + (~b_stage1[15:8] + 1'b1);
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Result combination
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_stage3 <= 16'b0;
            valid_stage3 <= 1'b0;
        end else begin
            diff_stage3 <= {diff_high_stage2, diff_low_stage2};
            valid_stage3 <= valid_stage2;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            diff <= diff_stage3;
            valid_out <= valid_stage3;
        end
    end

endmodule