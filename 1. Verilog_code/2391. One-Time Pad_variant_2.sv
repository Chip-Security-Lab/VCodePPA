//SystemVerilog
//IEEE 1364-2005 Verilog
module one_time_pad #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate, new_key,
    input wire [WIDTH-1:0] data_input, key_input,
    output reg [WIDTH-1:0] data_output,
    output reg ready
);
    // Pipeline registers - Input stage
    reg [WIDTH-1:0] current_key;
    
    // Stage 1: Input registration and mode detection
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] key_stage1;
    reg sub_mode_stage1;
    reg operation_active;
    
    // Stage 2: Data preprocessing
    reg [WIDTH-1:0] data_stage2;
    reg [WIDTH-1:0] key_stage2;
    reg sub_mode_stage2;
    reg operation_active_stage2;
    
    // Stage 3: Data inversion
    reg [WIDTH-1:0] inverted_data_stage3;
    reg [WIDTH-1:0] key_stage3;
    reg sub_mode_stage3;
    reg operation_active_stage3;
    
    // Stage 4: Preparation for computation
    reg [WIDTH-1:0] inverted_data_stage4;
    reg [WIDTH-1:0] key_stage4;
    reg sub_mode_stage4;
    reg operation_active_stage4;
    
    // Stage 5: Computation stage 1 - low bits operation
    reg [WIDTH/2-1:0] partial_result_low;
    reg [WIDTH/2-1:0] inverted_data_stage5_high;
    reg [WIDTH/2-1:0] key_stage5_high;
    reg sub_mode_stage5;
    reg operation_active_stage5;
    reg carry_stage5;
    
    // Stage 6: Computation stage 2 - high bits operation
    reg [WIDTH-1:0] computation_result;
    reg operation_active_stage6;
    
    // Control path
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ready <= 0;
            operation_active <= 0;
        end else begin
            // Key loading control
            if (new_key) begin
                ready <= 1;
                operation_active <= 0;
            end else if (activate && ready) begin
                operation_active <= 1;
                ready <= 0;  // One-time use
            end else begin
                operation_active <= 0;
            end
        end
    end
    
    // Data path - Stage 1: Input registration and mode detection
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_key <= {WIDTH{1'b0}};
            data_stage1 <= {WIDTH{1'b0}};
            key_stage1 <= {WIDTH{1'b0}};
            sub_mode_stage1 <= 1'b0;
        end else begin
            // Key registration
            if (new_key) begin
                current_key <= key_input;
            end
            
            // Data path stage 1
            if (activate && ready) begin
                data_stage1 <= data_input;
                key_stage1 <= current_key;
                sub_mode_stage1 <= data_input[WIDTH-1] ^ current_key[WIDTH-1];
            end
        end
    end
    
    // Data path - Stage 2: Data preprocessing
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            key_stage2 <= {WIDTH{1'b0}};
            sub_mode_stage2 <= 1'b0;
            operation_active_stage2 <= 1'b0;
        end else begin
            operation_active_stage2 <= operation_active;
            if (operation_active) begin
                data_stage2 <= data_stage1;
                key_stage2 <= key_stage1;
                sub_mode_stage2 <= sub_mode_stage1;
            end
        end
    end
    
    // Data path - Stage 3: Data inversion
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            inverted_data_stage3 <= {WIDTH{1'b0}};
            key_stage3 <= {WIDTH{1'b0}};
            sub_mode_stage3 <= 1'b0;
            operation_active_stage3 <= 1'b0;
        end else begin
            operation_active_stage3 <= operation_active_stage2;
            if (operation_active_stage2) begin
                inverted_data_stage3 <= sub_mode_stage2 ? ~data_stage2 : data_stage2;
                key_stage3 <= key_stage2;
                sub_mode_stage3 <= sub_mode_stage2;
            end
        end
    end
    
    // Data path - Stage 4: Preparation for computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            inverted_data_stage4 <= {WIDTH{1'b0}};
            key_stage4 <= {WIDTH{1'b0}};
            sub_mode_stage4 <= 1'b0;
            operation_active_stage4 <= 1'b0;
        end else begin
            operation_active_stage4 <= operation_active_stage3;
            if (operation_active_stage3) begin
                inverted_data_stage4 <= inverted_data_stage3;
                key_stage4 <= key_stage3;
                sub_mode_stage4 <= sub_mode_stage3;
            end
        end
    end
    
    // Data path - Stage 5: Computation stage 1 - low bits operation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            partial_result_low <= {(WIDTH/2){1'b0}};
            inverted_data_stage5_high <= {(WIDTH/2){1'b0}};
            key_stage5_high <= {(WIDTH/2){1'b0}};
            sub_mode_stage5 <= 1'b0;
            operation_active_stage5 <= 1'b0;
            carry_stage5 <= 1'b0;
        end else begin
            operation_active_stage5 <= operation_active_stage4;
            if (operation_active_stage4) begin
                // Split computation for better timing - compute low bits first
                if (sub_mode_stage4) begin
                    // Addition mode (with 1 for two's complement)
                    {carry_stage5, partial_result_low} <= 
                        {1'b0, inverted_data_stage4[WIDTH/2-1:0]} + 
                        {1'b0, key_stage4[WIDTH/2-1:0]} + 1'b1;
                end else begin
                    // Subtraction mode
                    {carry_stage5, partial_result_low} <= 
                        {1'b0, inverted_data_stage4[WIDTH/2-1:0]} - 
                        {1'b0, key_stage4[WIDTH/2-1:0]};
                end
                
                // Pass high bits to next stage
                inverted_data_stage5_high <= inverted_data_stage4[WIDTH-1:WIDTH/2];
                key_stage5_high <= key_stage4[WIDTH-1:WIDTH/2];
                sub_mode_stage5 <= sub_mode_stage4;
            end
        end
    end
    
    // Data path - Stage 6: Computation stage 2 - high bits operation and final result
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            computation_result <= {WIDTH{1'b0}};
            operation_active_stage6 <= 1'b0;
        end else begin
            operation_active_stage6 <= operation_active_stage5;
            if (operation_active_stage5) begin
                // Compute high bits using the carry from low bits
                if (sub_mode_stage5) begin
                    // Addition mode
                    computation_result[WIDTH-1:WIDTH/2] <= 
                        inverted_data_stage5_high + key_stage5_high + carry_stage5;
                end else begin
                    // Subtraction mode
                    computation_result[WIDTH-1:WIDTH/2] <= 
                        inverted_data_stage5_high - key_stage5_high - (carry_stage5 ? 1'b0 : 1'b1);
                end
                
                // Combine with low bits result
                computation_result[WIDTH/2-1:0] <= partial_result_low;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_output <= {WIDTH{1'b0}};
        end else begin
            // Register computation result to output
            if (operation_active_stage6) begin
                data_output <= computation_result;
            end
        end
    end
endmodule