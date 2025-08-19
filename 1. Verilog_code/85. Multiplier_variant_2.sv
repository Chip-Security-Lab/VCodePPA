//SystemVerilog
module Multiplier5(
    input clk,
    input rst_n,
    input [7:0] in_a, in_b,
    input in_valid,
    output reg [15:0] out,
    output reg out_valid
);

    // Pipeline stage 1 - Input registers
    reg [7:0] a_stage1, b_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Partial products
    wire [7:0][7:0] pp;
    reg [7:0][7:0] pp_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 - Extended partial products
    wire [7:0][15:0] pp_ext;
    reg [7:0][15:0] pp_ext_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 - First reduction
    wire [15:0] sum1;
    reg [15:0] sum1_stage4;
    reg [15:0] pp_ext_45_stage4;
    reg valid_stage4;
    
    // Pipeline stage 5 - Second reduction
    wire [15:0] sum2;
    reg [15:0] sum2_stage5;
    reg [15:0] pp_ext_67_stage5;
    reg valid_stage5;
    
    // Pipeline stage 6 - Final addition
    wire [15:0] sum3;
    reg valid_stage6;

    // Stage 1: Input registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_stage1 <= in_a;
            b_stage1 <= in_b;
            valid_stage1 <= in_valid;
        end
    end

    // Generate partial products
    genvar i, j;
    generate
        for(i=0; i<8; i=i+1) begin: pp_gen
            for(j=0; j<8; j=j+1) begin: pp_row
                assign pp[i][j] = a_stage1[j] & b_stage1[i];
            end
        end
    endgenerate

    // Stage 2: Partial products register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pp_stage2 <= 64'b0;
            valid_stage2 <= 1'b0;
        end else begin
            pp_stage2 <= pp;
            valid_stage2 <= valid_stage1;
        end
    end

    // Extend partial products
    generate
        for(i=0; i<8; i=i+1) begin: pp_ext_gen
            assign pp_ext[i] = {8'b0, pp_stage2[i]} << i;
        end
    endgenerate

    // Stage 3: Extended partial products register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pp_ext_stage3 <= 128'b0;
            valid_stage3 <= 1'b0;
        end else begin
            pp_ext_stage3 <= pp_ext;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: First reduction
    assign sum1 = pp_ext_stage3[0] + pp_ext_stage3[1] + pp_ext_stage3[2] + pp_ext_stage3[3];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum1_stage4 <= 16'b0;
            pp_ext_45_stage4 <= 16'b0;
            valid_stage4 <= 1'b0;
        end else begin
            sum1_stage4 <= sum1;
            pp_ext_45_stage4 <= pp_ext_stage3[4] + pp_ext_stage3[5];
            valid_stage4 <= valid_stage3;
        end
    end

    // Stage 5: Second reduction
    assign sum2 = sum1_stage4 + pp_ext_45_stage4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum2_stage5 <= 16'b0;
            pp_ext_67_stage5 <= 16'b0;
            valid_stage5 <= 1'b0;
        end else begin
            sum2_stage5 <= sum2;
            pp_ext_67_stage5 <= pp_ext_stage3[6] + pp_ext_stage3[7];
            valid_stage5 <= valid_stage4;
        end
    end

    // Stage 6: Final addition
    assign sum3 = sum2_stage5 + pp_ext_67_stage5;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 16'b0;
            out_valid <= 1'b0;
        end else begin
            out <= sum3;
            out_valid <= valid_stage5;
        end
    end

endmodule