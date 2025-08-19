//SystemVerilog
module fsm_signal_recovery (
    input wire clk, rst_n,
    input wire signal_detect,
    input wire [3:0] signal_value,
    output reg [3:0] recovered_value,
    output reg lock_status
);
    // FSM states
    localparam IDLE = 2'b00, DETECT = 2'b01, LOCK = 2'b10, TRACK = 2'b11;
    
    // State registers
    reg [1:0] state, next_state;
    
    // Pipeline stage registers
    reg [3:0] counter;
    reg signal_detect_stage1, signal_detect_stage2;
    reg [3:0] signal_value_stage1, signal_value_stage2;
    
    // Multiply pipeline registers
    reg [3:0] multiplier_stage1, multiplier_stage2, multiplier_stage3;
    reg [3:0] multiplicand_stage1, multiplicand_stage2, multiplicand_stage3;
    reg [3:0] shift_accumulator_stage1, shift_accumulator_stage2, shift_accumulator_stage3;
    reg [2:0] shift_counter_stage1, shift_counter_stage2, shift_counter_stage3;
    
    // Control signals with pipeline stages
    reg multiply_active_stage1, multiply_active_stage2, multiply_active_stage3;
    reg multiply_done_stage1, multiply_done_stage2, multiply_done_stage3;
    
    // Results pipeline
    reg [3:0] multiply_result_stage1, multiply_result_stage2, multiply_result_stage3;
    
    // State register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end
    
    // Next state logic - combinational
    always @(*) begin
        case (state)
            IDLE: next_state = signal_detect_stage2 ? DETECT : IDLE;
            DETECT: next_state = (counter >= 4'd8) ? LOCK : DETECT;
            LOCK: next_state = signal_detect_stage2 ? TRACK : IDLE;
            TRACK: next_state = signal_detect_stage2 ? TRACK : IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Input signal pipelining
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_detect_stage1 <= 1'b0;
            signal_detect_stage2 <= 1'b0;
            signal_value_stage1 <= 4'd0;
            signal_value_stage2 <= 4'd0;
        end else begin
            signal_detect_stage1 <= signal_detect;
            signal_detect_stage2 <= signal_detect_stage1;
            signal_value_stage1 <= signal_value;
            signal_value_stage2 <= signal_value_stage1;
        end
    end

    // Pipeline stage 1: Setup and initial computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            lock_status <= 1'b0;
            multiplier_stage1 <= 4'd0;
            multiplicand_stage1 <= 4'd0;
            shift_accumulator_stage1 <= 4'd0;
            shift_counter_stage1 <= 3'd0;
            multiply_active_stage1 <= 1'b0;
            multiply_done_stage1 <= 1'b0;
        end else case (state)
            IDLE: begin
                counter <= 4'd0;
                lock_status <= 1'b0;
                multiply_active_stage1 <= 1'b0;
                multiply_done_stage1 <= 1'b0;
            end
            DETECT: begin
                counter <= counter + 1'b1;
                if (!multiply_done_stage3) begin
                    multiply_active_stage1 <= 1'b1;
                end
            end
            LOCK: begin
                multiplier_stage1 <= signal_value_stage2;
                multiplicand_stage1 <= signal_value_stage2;
                shift_accumulator_stage1 <= 4'd0;
                shift_counter_stage1 <= 3'd0;
                multiply_active_stage1 <= 1'b1;
                multiply_done_stage1 <= 1'b0;
                lock_status <= 1'b1;
            end
            TRACK: begin
                multiplier_stage1 <= signal_value_stage2;
                multiplicand_stage1 <= signal_value_stage2;
                shift_accumulator_stage1 <= 4'd0;
                shift_counter_stage1 <= 3'd0;
                multiply_active_stage1 <= 1'b1;
                multiply_done_stage1 <= 1'b0;
            end
        endcase
    end

    // Pipeline stage 2: Multiplication calculation part 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplier_stage2 <= 4'd0;
            multiplicand_stage2 <= 4'd0;
            shift_accumulator_stage2 <= 4'd0;
            shift_counter_stage2 <= 3'd0;
            multiply_active_stage2 <= 1'b0;
            multiply_done_stage2 <= 1'b0;
        end else begin
            multiplier_stage2 <= multiplier_stage1;
            multiplicand_stage2 <= multiplicand_stage1;
            shift_counter_stage2 <= shift_counter_stage1;
            multiply_active_stage2 <= multiply_active_stage1;
            multiply_done_stage2 <= multiply_done_stage1;
            
            if (multiply_active_stage1 && !multiply_done_stage1) begin
                if (shift_counter_stage1 < 3'd2) begin  // First half of multiplication steps
                    shift_accumulator_stage2 <= (multiplier_stage1[0]) ? 
                                               shift_accumulator_stage1 + multiplicand_stage1 : 
                                               shift_accumulator_stage1;
                    // Prepare for next iteration
                    shift_counter_stage2 <= shift_counter_stage1 + 1'b1;
                end else begin
                    shift_accumulator_stage2 <= shift_accumulator_stage1;
                end
            end else begin
                shift_accumulator_stage2 <= shift_accumulator_stage1;
            end
        end
    end

    // Pipeline stage 3: Multiplication calculation part 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplier_stage3 <= 4'd0;
            multiplicand_stage3 <= 4'd0;
            shift_accumulator_stage3 <= 4'd0;
            shift_counter_stage3 <= 3'd0;
            multiply_active_stage3 <= 1'b0;
            multiply_done_stage3 <= 1'b0;
            multiply_result_stage3 <= 4'd0;
            recovered_value <= 4'd0;
        end else begin
            // Forward pipeline registers
            multiplier_stage3 <= multiplier_stage2 >> 1;  // Shift for next iteration
            multiplicand_stage3 <= multiplicand_stage2 << 1;  // Shift for next iteration
            shift_counter_stage3 <= shift_counter_stage2;
            multiply_active_stage3 <= multiply_active_stage2;
            multiply_done_stage3 <= multiply_done_stage2;
            
            if (multiply_active_stage2 && !multiply_done_stage2) begin
                if (shift_counter_stage2 >= 3'd2 && shift_counter_stage2 < 3'd4) begin  // Second half of multiplication steps
                    shift_accumulator_stage3 <= (multiplier_stage2[0]) ? 
                                               shift_accumulator_stage2 + multiplicand_stage2 : 
                                               shift_accumulator_stage2;
                    
                    if (shift_counter_stage2 == 3'd3) begin
                        multiply_done_stage3 <= 1'b1;
                        multiply_result_stage3 <= (multiplier_stage2[0]) ? 
                                                 shift_accumulator_stage2 + multiplicand_stage2 : 
                                                 shift_accumulator_stage2;
                        recovered_value <= (multiplier_stage2[0]) ? 
                                          shift_accumulator_stage2 + multiplicand_stage2 : 
                                          shift_accumulator_stage2;
                    end
                end else begin
                    shift_accumulator_stage3 <= shift_accumulator_stage2;
                end
            end else begin
                shift_accumulator_stage3 <= shift_accumulator_stage2;
                if (multiply_done_stage2) begin
                    recovered_value <= multiply_result_stage3;
                end
            end
        end
    end
endmodule