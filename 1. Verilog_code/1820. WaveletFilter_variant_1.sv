//SystemVerilog
module WaveletFilter #(parameter W=8) (
    input clk,
    input rst_n,
    input [W-1:0] din,
    output reg [W-1:0] approx,
    output reg [W-1:0] detail
);

    // Stage 1 registers
    reg [W-1:0] din_stage1;
    reg [W-1:0] prev_sample_stage1;
    
    // Stage 2 registers  
    reg [W-1:0] din_inv_stage2;
    reg [W-1:0] prev_inv_stage2;
    reg [W-1:0] prev_sample_stage2;
    
    // Stage 3 registers
    reg [W-1:0] sum_stage3;
    reg [W-1:0] diff_stage3;
    reg borrow_stage3;
    reg [W-1:0] prev_sample_stage3;
    
    // Stage 4 registers
    reg [W-1:0] detail_stage4;
    reg [W-1:0] approx_stage4;

    // Stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= 0;
            prev_sample_stage1 <= 0;
        end else begin
            din_stage1 <= din;
            prev_sample_stage1 <= prev_sample_stage3;
        end
    end

    // Stage 2: Inversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_inv_stage2 <= 0;
            prev_inv_stage2 <= 0;
            prev_sample_stage2 <= 0;
        end else begin
            din_inv_stage2 <= ~din_stage1;
            prev_inv_stage2 <= ~prev_sample_stage1;
            prev_sample_stage2 <= prev_sample_stage1;
        end
    end

    // Stage 3: Addition and subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage3 <= 0;
            diff_stage3 <= 0;
            borrow_stage3 <= 0;
            prev_sample_stage3 <= 0;
        end else begin
            {borrow_stage3, diff_stage3} <= din_stage1 + prev_inv_stage2 + 1'b1;
            sum_stage3 <= din_stage1 + prev_sample_stage2;
            prev_sample_stage3 <= prev_sample_stage2;
        end
    end

    // Stage 4: Final calculations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detail_stage4 <= 0;
            approx_stage4 <= 0;
        end else begin
            detail_stage4 <= borrow_stage3 ? diff_stage3 : ~diff_stage3;
            approx_stage4 <= sum_stage3 >> 1;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            approx <= 0;
            detail <= 0;
        end else begin
            approx <= approx_stage4;
            detail <= detail_stage4;
        end
    end

endmodule