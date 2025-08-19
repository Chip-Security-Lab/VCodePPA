//SystemVerilog
module one_time_pad #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate, new_key,
    input wire [WIDTH-1:0] data_input, key_input,
    output reg [WIDTH-1:0] data_output,
    output reg ready
);
    // State and key registers
    reg [WIDTH-1:0] current_key;
    reg [WIDTH-1:0] data_stage1, data_stage2;
    reg [WIDTH-1:0] key_stage1, key_stage2;
    reg activate_stage1, activate_stage2;
    
    // Processing control registers - optimized state encoding
    reg processing_active;
    reg [1:0] pipeline_stage;
    reg key_valid;
    
    // Simplified XOR operation registers with balanced logic paths
    reg [WIDTH-1:0] xor_result;
    
    // Control path logic with reduced state transitions
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            processing_active <= 1'b0;
            pipeline_stage <= 2'b00;
            key_valid <= 1'b0;
            ready <= 1'b0;
        end 
        else begin
            if (new_key) begin
                key_valid <= 1'b1;
                ready <= 1'b1;
                processing_active <= 1'b0;
                pipeline_stage <= 2'b00;
            end
            else if (activate_stage2 && key_valid) begin
                processing_active <= 1'b1;
                ready <= 1'b0;
                pipeline_stage <= 2'b01;
            end
            else if (processing_active) begin
                if (pipeline_stage == 2'b10) begin
                    pipeline_stage <= 2'b00;
                    processing_active <= 1'b0;
                    ready <= 1'b1;
                end
                else begin
                    pipeline_stage <= pipeline_stage + 1'b1;
                end
            end
        end
    end
    
    // Optimized data path with single-cycle XOR operation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_key <= {WIDTH{1'b0}};
            data_stage1 <= {WIDTH{1'b0}};
            data_stage2 <= {WIDTH{1'b0}};
            key_stage1 <= {WIDTH{1'b0}};
            key_stage2 <= {WIDTH{1'b0}};
            activate_stage1 <= 1'b0;
            activate_stage2 <= 1'b0;
            xor_result <= {WIDTH{1'b0}};
            data_output <= {WIDTH{1'b0}};
        end 
        else begin
            // Pipeline stages for input registration
            data_stage1 <= data_input;
            key_stage1 <= key_input;
            activate_stage1 <= activate;
            
            data_stage2 <= data_stage1;
            key_stage2 <= key_stage1;
            activate_stage2 <= activate_stage1;
            
            // Key update logic - optimized for single cycle update
            if (new_key) begin
                current_key <= key_input; // Direct path for faster key update
            end
            
            // Single-stage XOR operation with optimized timing
            if (processing_active && pipeline_stage == 2'b01) begin
                xor_result <= data_stage2 ^ current_key;
            end
            
            // Output stage with reduced critical path
            if (processing_active && pipeline_stage == 2'b10) begin
                data_output <= xor_result;
            end
        end
    end
endmodule