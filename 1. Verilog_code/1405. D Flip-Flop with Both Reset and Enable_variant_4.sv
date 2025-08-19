//SystemVerilog
module d_ff_pipeline (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire d_in,
    input wire valid_in,
    output wire ready_in,
    output wire valid_out,
    input wire ready_out,
    output wire d_out
);
    // Pipeline stage control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline stage data registers
    reg d_stage1, d_stage2, d_stage3;
    
    // Optimized flow control logic - backward ready chain
    // Restructured to reduce logic depth and improve timing
    wire valid_and_ready_stage3 = valid_stage3 && ready_out;
    wire valid_and_ready_stage2 = valid_stage2 && (!valid_stage3 || ready_out);
    wire valid_and_ready_stage1 = valid_stage1 && (!valid_stage2 || !valid_stage3 || ready_out);
    
    assign ready_in = !valid_stage1 || !valid_stage2 || !valid_stage3 || ready_out;
    
    // Stage 1 - Input capture stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (en) begin
            if (valid_in && !valid_and_ready_stage1) begin
                d_stage1 <= d_in;
                valid_stage1 <= 1'b1;
            end else if (valid_and_ready_stage1) begin
                valid_stage1 <= valid_in;
                d_stage1 <= valid_in ? d_in : d_stage1;
            end
        end
    end
    
    // Stage 2 - Processing stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (en) begin
            if (valid_and_ready_stage1 && !valid_and_ready_stage2) begin
                d_stage2 <= d_stage1;
                valid_stage2 <= 1'b1;
            end else if (valid_and_ready_stage2) begin
                valid_stage2 <= valid_and_ready_stage1;
                d_stage2 <= valid_and_ready_stage1 ? d_stage1 : d_stage2;
            end
        end
    end
    
    // Stage 3 - Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (en) begin
            if (valid_and_ready_stage2 && !valid_and_ready_stage3) begin
                d_stage3 <= d_stage2;
                valid_stage3 <= 1'b1;
            end else if (valid_and_ready_stage3) begin
                valid_stage3 <= valid_and_ready_stage2;
                d_stage3 <= valid_and_ready_stage2 ? d_stage2 : d_stage3;
            end
        end
    end
    
    // Output assignments
    assign d_out = d_stage3;
    assign valid_out = valid_stage3;

endmodule