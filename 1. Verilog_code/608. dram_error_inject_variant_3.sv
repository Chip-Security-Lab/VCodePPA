//SystemVerilog
module dram_error_inject #(
    parameter ERROR_MASK = 8'hFF
)(
    input clk,
    input rst_n,
    input enable,
    input [63:0] data_in,
    output reg [63:0] data_out
);

    // Pipeline stage 1 registers
    reg enable_stage1;
    reg [63:0] data_in_stage1;
    
    // Pipeline stage 2 registers
    reg enable_stage2;
    reg [63:0] data_in_stage2;
    reg [63:0] error_mask_stage2;
    
    // Pipeline stage 3 registers
    reg [63:0] data_out_stage3;

    // Stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
            data_in_stage1 <= 64'b0;
        end else begin
            enable_stage1 <= enable;
            data_in_stage1 <= data_in;
        end
    end

    // Stage 2: Error mask preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
            data_in_stage2 <= 64'b0;
            error_mask_stage2 <= 64'b0;
        end else begin
            enable_stage2 <= enable_stage1;
            data_in_stage2 <= data_in_stage1;
            error_mask_stage2 <= {8{ERROR_MASK}};
        end
    end

    // Stage 3: Error injection and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 64'b0;
        end else begin
            if (enable_stage2) begin
                data_out_stage3 <= data_in_stage2 ^ error_mask_stage2;
            end else begin
                data_out_stage3 <= data_in_stage2;
            end
        end
    end

    // Output assignment
    assign data_out = data_out_stage3;

endmodule