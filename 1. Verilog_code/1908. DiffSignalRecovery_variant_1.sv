//SystemVerilog
// SystemVerilog
module DiffSignalRecovery #(parameter THRESHOLD=100) (
    input wire clk,
    input wire rst_n,  // Reset signal for pipeline control
    input wire diff_p, 
    input wire diff_n,
    input wire valid_in,  // Input valid signal
    output wire valid_out, // Output valid signal
    output wire recovered
);
    // Internal signals
    wire signed [15:0] diff_value;
    wire greater_than_threshold;
    wire less_than_neg_threshold;
    wire next_recovered;
    
    // Registered signals for pipeline stages
    reg signed [15:0] diff_stage1;
    reg greater_than_threshold_stage1;
    reg less_than_neg_threshold_stage1;
    reg valid_stage1;
    reg recovered_stage1;
    reg valid_stage2;
    reg recovered_reg;
    
    // =============================================
    // Combinational logic for difference calculation
    // =============================================
    assign diff_value = diff_p - diff_n;
    assign greater_than_threshold = diff_value > THRESHOLD;
    assign less_than_neg_threshold = diff_value < -THRESHOLD;
    
    // =============================================
    // Combinational logic for output determination
    // =============================================
    assign next_recovered = valid_stage1 ? (
                            greater_than_threshold_stage1 ? 1'b1 :
                            less_than_neg_threshold_stage1 ? 1'b0 :
                            recovered_stage1) : recovered_reg;
    
    // Output assignment
    assign recovered = recovered_reg;
    assign valid_out = valid_stage2;
    
    // =============================================
    // Sequential logic for pipeline stage 1
    // =============================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_stage1 <= 16'd0;
            greater_than_threshold_stage1 <= 1'b0;
            less_than_neg_threshold_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            recovered_stage1 <= 1'b0;
        end else begin
            diff_stage1 <= diff_value;
            greater_than_threshold_stage1 <= greater_than_threshold;
            less_than_neg_threshold_stage1 <= less_than_neg_threshold;
            valid_stage1 <= valid_in;
            recovered_stage1 <= recovered_reg;
        end
    end
    
    // =============================================
    // Sequential logic for pipeline stage 2
    // =============================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_reg <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            recovered_reg <= next_recovered;
        end
    end
    
endmodule