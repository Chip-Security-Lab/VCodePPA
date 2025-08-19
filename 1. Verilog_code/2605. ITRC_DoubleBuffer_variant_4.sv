//SystemVerilog
module ITRC_DoubleBuffer #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] raw_status,
    output reg [WIDTH-1:0] stable_status
);

    // Pipeline registers
    reg [WIDTH-1:0] stage1_reg;
    reg [WIDTH-1:0] stage2_reg;
    
    // Pipeline valid signals
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: First buffer - Data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= {WIDTH{1'b0}};
        end else begin
            stage1_reg <= raw_status;
        end
    end

    // Stage 1: First buffer - Control path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Second buffer - Data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_reg <= {WIDTH{1'b0}};
        end else begin
            stage2_reg <= stage1_reg;
        end
    end

    // Stage 2: Second buffer - Control path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage - Data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_status <= {WIDTH{1'b0}};
        end else begin
            stable_status <= stage2_reg;
        end
    end

endmodule