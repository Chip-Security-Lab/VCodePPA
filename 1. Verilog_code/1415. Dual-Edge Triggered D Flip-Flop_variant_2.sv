//SystemVerilog
module dual_edge_d_ff (
    input wire clk,
    input wire rst_n,  // Added reset signal for proper pipeline control
    input wire d,
    input wire valid_in,  // Added valid signal for pipeline control
    output reg q,
    output reg valid_out  // Output valid signal for pipeline handshaking
);
    // Pipeline stage registers
    reg stage1_data;
    reg stage1_valid;
    
    reg stage2_pos_data;
    reg stage2_neg_data;
    reg stage2_valid;
    
    // Stage 1: Input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_data <= d;
            stage1_valid <= valid_in;
        end
    end
    
    // Stage 2: Edge-specific processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_pos_data <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_pos_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_neg_data <= 1'b0;
        end else begin
            stage2_neg_data <= stage1_data;
        end
    end
    
    // Output stage: Multiplexing and final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= stage2_valid;
            if (stage2_valid) begin
                q <= clk ? stage2_pos_data : stage2_neg_data;
            end
        end
    end
endmodule