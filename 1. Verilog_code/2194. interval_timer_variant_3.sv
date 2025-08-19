//SystemVerilog
module interval_timer (
    input wire clk,
    input wire rst,
    input wire program_en,
    input wire [7:0] interval_data,
    input wire [3:0] interval_sel,
    output reg event_trigger
);
    // Memory for storing interval values
    reg [7:0] intervals [0:15];
    
    // Pipeline stage 1 registers
    reg [7:0] current_count_stage1;
    reg [3:0] active_interval_stage1;
    reg stage1_valid;
    
    // Pipeline stage 2 registers
    reg [7:0] interval_value_stage2;
    reg [7:0] current_count_stage2;
    reg [3:0] active_interval_stage2;
    reg stage2_valid;
    
    // Pipeline stage 3 registers
    reg count_complete_stage3;
    reg [3:0] next_interval_stage3;
    reg stage3_valid;
    
    // Stage 1: Counter increment and memory read
    always @(posedge clk) begin
        case ({rst, program_en})
            2'b10, 2'b11: begin  // Reset has highest priority
                current_count_stage1 <= 8'd0;
                active_interval_stage1 <= 4'd0;
                stage1_valid <= 1'b0;
            end
            
            2'b01: begin  // Program mode
                intervals[interval_sel] <= interval_data;
                stage1_valid <= 1'b0;
            end
            
            2'b00: begin  // Normal operation
                current_count_stage1 <= (stage3_valid && count_complete_stage3) ? 8'd0 : current_count_stage1 + 1'b1;
                active_interval_stage1 <= (stage3_valid && count_complete_stage3) ? next_interval_stage3 : active_interval_stage1;
                stage1_valid <= 1'b1;
            end
        endcase
    end
    
    // Stage 2: Comparison
    always @(posedge clk) begin
        case ({rst, stage1_valid, program_en})
            3'b100, 3'b101, 3'b110, 3'b111: begin  // Reset has highest priority
                interval_value_stage2 <= 8'd0;
                current_count_stage2 <= 8'd0;
                active_interval_stage2 <= 4'd0;
                stage2_valid <= 1'b0;
            end
            
            3'b010: begin  // Valid data from stage 1 and not in program mode
                interval_value_stage2 <= intervals[active_interval_stage1];
                current_count_stage2 <= current_count_stage1;
                active_interval_stage2 <= active_interval_stage1;
                stage2_valid <= 1'b1;
            end
            
            default: begin  // All other cases
                stage2_valid <= 1'b0;
            end
        endcase
    end
    
    // Stage 3: Result processing
    always @(posedge clk) begin
        case ({rst, stage2_valid})
            2'b10, 2'b11: begin  // Reset has highest priority
                count_complete_stage3 <= 1'b0;
                next_interval_stage3 <= 4'd0;
                stage3_valid <= 1'b0;
                event_trigger <= 1'b0;
            end
            
            2'b01: begin  // Valid data from stage 2
                count_complete_stage3 <= (current_count_stage2 >= interval_value_stage2);
                next_interval_stage3 <= active_interval_stage2 + 1'b1;
                stage3_valid <= 1'b1;
                event_trigger <= (current_count_stage2 >= interval_value_stage2);
            end
            
            2'b00: begin  // No valid data
                event_trigger <= 1'b0;
                stage3_valid <= 1'b0;
            end
        endcase
    end
endmodule