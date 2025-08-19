//SystemVerilog
module idea_math_unit (
    input clk,
    input reset,
    // Valid-Ready handshake interface
    input valid_in,       // Sender indicates data valid
    output reg ready_in,  // Receiver indicates ready to accept
    input [15:0] x, y,    // Data inputs
    input mul_mode,       // Operation mode selection
    
    output reg valid_out, // Sender indicates result valid
    input ready_out,      // Receiver indicates ready to accept result
    output reg [15:0] result // Result output
);
    // Pipeline stage registers
    reg [15:0] x_stage1, y_stage1;
    reg [15:0] x_stage2, y_stage2;
    reg mul_mode_stage1, mul_mode_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [31:0] mul_temp_stage2;
    reg [15:0] add_temp_stage2;
    reg [15:0] result_stage3;
    
    // Pipeline control signals
    reg processing_stage1, processing_stage2, processing_stage3;
    
    // First pipeline stage - Input capture and multiplication start
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_stage1 <= 16'h0;
            y_stage1 <= 16'h0;
            mul_mode_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            processing_stage1 <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            // Input handshake
            if (valid_in && ready_in) begin
                x_stage1 <= x;
                y_stage1 <= y;
                mul_mode_stage1 <= mul_mode;
                valid_stage1 <= 1'b1;
                processing_stage1 <= 1'b1;
                ready_in <= 1'b0;
            end else if (processing_stage1 && !valid_stage2) begin
                // Transfer to next stage completed
                valid_stage1 <= 1'b0;
                processing_stage1 <= 1'b0;
            end
            
            // Ready for new input when pipeline advances
            if (valid_stage3 && ready_out) begin
                ready_in <= 1'b1;
            end
        end
    end
    
    // Second pipeline stage - Multiplication and addition computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_stage2 <= 16'h0;
            y_stage2 <= 16'h0;
            mul_mode_stage2 <= 1'b0;
            mul_temp_stage2 <= 32'h0;
            add_temp_stage2 <= 16'h0;
            valid_stage2 <= 1'b0;
            processing_stage2 <= 1'b0;
        end else begin
            // Receive from previous stage
            if (valid_stage1 && !processing_stage2) begin
                x_stage2 <= x_stage1;
                y_stage2 <= y_stage1;
                mul_mode_stage2 <= mul_mode_stage1;
                mul_temp_stage2 <= x_stage1 * y_stage1;
                add_temp_stage2 <= (x_stage1 + y_stage1) % 16'h10000;
                valid_stage2 <= 1'b1;
                processing_stage2 <= 1'b1;
            end else if (processing_stage2 && !valid_stage3) begin
                // Transfer to next stage completed
                valid_stage2 <= 1'b0;
                processing_stage2 <= 1'b0;
            end
        end
    end
    
    // Third pipeline stage - Modulo operation and result selection
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result_stage3 <= 16'h0;
            valid_stage3 <= 1'b0;
            processing_stage3 <= 1'b0;
            valid_out <= 1'b0;
            result <= 16'h0;
        end else begin
            // Receive from previous stage
            if (valid_stage2 && !processing_stage3) begin
                // Final computation based on mode
                if (mul_mode_stage2) begin
                    result_stage3 <= (mul_temp_stage2 == 32'h0) ? 16'hFFFF : (mul_temp_stage2 % 17'h10001);
                end else begin
                    result_stage3 <= add_temp_stage2;
                end
                valid_stage3 <= 1'b1;
                processing_stage3 <= 1'b1;
            end
            
            // Output handshake
            if (valid_stage3 && !valid_out) begin
                valid_out <= 1'b1;
                result <= result_stage3;
            end
            
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                valid_stage3 <= 1'b0;
                processing_stage3 <= 1'b0;
            end
        end
    end
    
endmodule