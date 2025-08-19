//SystemVerilog IEEE 1364-2005
module Matrix_XNOR(
    input clk,
    input rst_n,
    // Input interface
    input [3:0] row,
    input [3:0] col,
    input valid_in,
    output reg ready_in,
    // Output interface
    output reg [7:0] mat_res,
    output reg valid_out,
    input ready_out
);
    // Pipeline registers and control signals
    reg [3:0] row_stage1, col_stage1;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [7:0] xnor_result_stage2;
    reg [7:0] inverted_result_stage3;
    
    // First pipeline stage - capture inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_stage1 <= 4'h0;
            col_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
        end else if (ready_in && valid_in) begin
            row_stage1 <= row;
            col_stage1 <= col;
            valid_stage1 <= 1'b1;
        end else if (valid_stage3 && ready_out) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Second pipeline stage - compute XNOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                xnor_result_stage2 <= ({row_stage1, col_stage1} ^ 8'h55);
                valid_stage2 <= 1'b1;
            end else if (valid_stage3 && ready_out) begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Third pipeline stage - invert the result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_result_stage3 <= 8'h00;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                inverted_result_stage3 <= ~xnor_result_stage2;
                valid_stage3 <= 1'b1;
            end else if (valid_stage3 && ready_out) begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Output stage and handshaking control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mat_res <= 8'h00;
            valid_out <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            // Output result when third stage is valid
            if (valid_stage3 && !valid_out) begin
                mat_res <= inverted_result_stage3;
                valid_out <= 1'b1;
            end
            
            // Handle output handshaking
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
            end
            
            // Input ready signal control
            if (ready_in && valid_in) begin
                ready_in <= 1'b0;
            end else if (valid_stage3 && ready_out) begin
                ready_in <= 1'b1;
            end
        end
    end
endmodule