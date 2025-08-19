//SystemVerilog
module parity_check_recovery (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire parity_in,
    output reg [7:0] data_out,
    output reg valid,
    output reg error
);
    // Stage 1: Calculate parity and register inputs
    reg [7:0] data_stage1;
    reg parity_in_stage1;
    wire calculated_parity_stage1;
    reg valid_stage1;
    
    assign calculated_parity_stage1 = ^data_in;
    
    // Stage 2: Compare parity and determine output
    reg [7:0] data_stage2;
    reg parity_match_stage2;
    reg valid_stage2;
    
    // Stage 1 registers management
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= 8'h00;
            parity_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            parity_in_stage1 <= parity_in;
            valid_stage1 <= 1'b1; // Input is always valid one cycle after reset
        end
    end
    
    // Stage 2 registers management
    always @(posedge clk) begin
        if (reset) begin
            data_stage2 <= 8'h00;
            parity_match_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            parity_match_stage2 <= (parity_in_stage1 == calculated_parity_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Valid output generation
    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
        end else begin
            valid <= valid_stage2;
        end
    end
    
    // Error output generation
    always @(posedge clk) begin
        if (reset) begin
            error <= 1'b0;
        end else begin
            error <= valid_stage2 & ~parity_match_stage2;
        end
    end
    
    // Data output management
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 8'h00;
        end else if (valid_stage2 && parity_match_stage2) begin
            data_out <= data_stage2;
        end
        // Keep last valid data if parity error (implicit)
    end
endmodule