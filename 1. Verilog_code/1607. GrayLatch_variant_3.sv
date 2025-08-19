//SystemVerilog
module GrayLatch #(parameter DW=4) (
    input clk,
    input rst_n,
    input en,
    input [DW-1:0] bin_in,
    output reg [DW-1:0] gray_out
);

    // Pipeline stage 1: Input register
    reg [DW-1:0] bin_in_stage1;
    reg en_stage1;
    
    // Pipeline stage 2: Gray code computation
    reg [DW-1:0] gray_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Output register
    reg [DW-1:0] gray_stage3;
    reg valid_stage3;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_in_stage1 <= {DW{1'b0}};
            en_stage1 <= 1'b0;
        end else begin
            bin_in_stage1 <= bin_in;
            en_stage1 <= en;
        end
    end

    // Stage 2: Gray code computation using conditional inversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (en_stage1) begin
                // Conditional inversion based on LSB
                gray_stage2 <= bin_in_stage1[DW-1:1] ^ {bin_in_stage1[DW-2:0], 1'b0};
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                gray_out <= gray_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

endmodule