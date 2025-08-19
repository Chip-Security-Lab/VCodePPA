//SystemVerilog
module pl_reg_dualport #(parameter W=16) (
    input wire clk,
    input wire reset,
    input wire wr1_en, 
    input wire wr2_en,
    input wire [W-1:0] wr1_data, 
    input wire [W-1:0] wr2_data,
    input wire valid_in,
    output wire valid_out,
    output wire [W-1:0] q
);
    // Pipeline stage 1 - Input capture and priority determination
    reg [W-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Output register
    reg [W-1:0] q_stage2;
    reg valid_stage2;
    
    // Stage 1: Capture inputs and determine priority with flattened if-else structure
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= {W{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else if (valid_in && (wr1_en || wr2_en)) begin
            valid_stage1 <= 1'b1;
            if (wr1_en) begin
                data_stage1 <= wr1_data; // wr1 has priority
            end
            else if (wr2_en) begin
                data_stage1 <= wr2_data;
            end
        end
        else if (valid_in) begin
            valid_stage1 <= 1'b1;
            data_stage1 <= data_stage1; // No change when no write enable
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Output register
    always @(posedge clk) begin
        if (reset) begin
            q_stage2 <= {W{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            q_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignments
    assign q = q_stage2;
    assign valid_out = valid_stage2;
    
endmodule