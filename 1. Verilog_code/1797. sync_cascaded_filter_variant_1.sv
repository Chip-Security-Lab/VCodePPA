//SystemVerilog
module sync_cascaded_filter #(
    parameter DATA_W = 8
)(
    input clk, rst_n,
    input [DATA_W-1:0] in_data,
    output reg [DATA_W-1:0] out_data
);

    // Pipeline stage 1 registers
    reg [DATA_W-1:0] in_data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers 
    reg [DATA_W-1:0] hp_out_stage2;
    reg [DATA_W-1:0] stage1_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [DATA_W-1:0] stage2_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 registers
    reg [DATA_W-1:0] out_data_stage4;
    reg valid_stage4;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            in_data_stage1 <= in_data;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: High-pass filter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hp_out_stage2 <= 0;
            stage1_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            hp_out_stage2 <= in_data_stage1 - stage1_stage2;
            stage1_stage2 <= in_data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Low-pass filter preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            stage2_stage3 <= stage1_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Output calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data_stage4 <= 0;
            valid_stage4 <= 0;
        end else begin
            out_data_stage4 <= (stage1_stage2 + stage2_stage3) >> 1;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 0;
        end else begin
            out_data <= valid_stage4 ? out_data_stage4 : out_data;
        end
    end

endmodule