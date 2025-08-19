//SystemVerilog
module recovery_sequence_controller(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger_recovery,
    output reg  [3:0]  recovery_stage,
    output reg         recovery_in_progress,
    output reg         system_reset,
    output reg         module_reset,
    output reg         memory_clear
);

    // State Encoding
    localparam IDLE       = 3'd0,
               RESET      = 3'd1,
               MODULE_RST = 3'd2,
               MEM_CLEAR  = 3'd3,
               WAIT       = 3'd4;

    // Stage 1: Input Latch and State Register
    reg  [2:0]  state_stage1, state_stage2, state_stage3, state_stage4;
    reg  [7:0]  counter_stage1, counter_stage2, counter_stage3, counter_stage4;
    reg         trigger_recovery_stage1, trigger_recovery_stage2, trigger_recovery_stage3, trigger_recovery_stage4;
    reg         rst_n_stage1, rst_n_stage2, rst_n_stage3, rst_n_stage4;

    // Stage 2: Control Signals
    reg         system_reset_stage2, module_reset_stage3, memory_clear_stage4;
    reg  [3:0]  recovery_stage_stage2, recovery_stage_stage3, recovery_stage_stage4;
    reg         recovery_in_progress_stage2, recovery_in_progress_stage3, recovery_in_progress_stage4;

    // Valid chain for pipeline control
    reg         valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg         flush_stage1, flush_stage2, flush_stage3, flush_stage4;

    // Optimized: Range and equality checks
    wire is_counter1_max_reset    = (counter_stage1 == 8'hFF);
    wire is_counter1_max_modrst   = (counter_stage1 == 8'h7F);
    wire is_counter1_max_memclr   = (counter_stage1 == 8'h3F);
    wire is_counter1_max_wait     = (counter_stage1 == 8'hFF);

    // Stage 1: Latch inputs and state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            counter_stage1 <= 8'h00;
            trigger_recovery_stage1 <= 1'b0;
            rst_n_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            flush_stage1 <= 1'b0;
        end else begin
            trigger_recovery_stage1 <= trigger_recovery;
            rst_n_stage1 <= rst_n;
            valid_stage1 <= 1'b1;
            flush_stage1 <= 1'b0;

            // Optimized state transition logic
            case (state_stage1)
                IDLE: begin
                    if (trigger_recovery) begin
                        state_stage1 <= RESET;
                        counter_stage1 <= 8'h00;
                    end else begin
                        state_stage1 <= IDLE;
                        counter_stage1 <= counter_stage1;
                    end
                end
                RESET: begin
                    if (is_counter1_max_reset) begin
                        state_stage1 <= MODULE_RST;
                        counter_stage1 <= 8'h00;
                    end else begin
                        state_stage1 <= RESET;
                        counter_stage1 <= counter_stage1 + 1'b1;
                    end
                end
                MODULE_RST: begin
                    if (is_counter1_max_modrst) begin
                        state_stage1 <= MEM_CLEAR;
                        counter_stage1 <= 8'h00;
                    end else begin
                        state_stage1 <= MODULE_RST;
                        counter_stage1 <= counter_stage1 + 1'b1;
                    end
                end
                MEM_CLEAR: begin
                    if (is_counter1_max_memclr) begin
                        state_stage1 <= WAIT;
                        counter_stage1 <= 8'h00;
                    end else begin
                        state_stage1 <= MEM_CLEAR;
                        counter_stage1 <= counter_stage1 + 1'b1;
                    end
                end
                WAIT: begin
                    if (is_counter1_max_wait) begin
                        state_stage1 <= IDLE;
                        counter_stage1 <= 8'h00;
                    end else begin
                        state_stage1 <= WAIT;
                        counter_stage1 <= counter_stage1 + 1'b1;
                    end
                end
                default: begin
                    state_stage1 <= IDLE;
                    counter_stage1 <= 8'h00;
                end
            endcase

            // Flush logic on reset or end of operation
            if (state_stage1 == WAIT && is_counter1_max_wait) begin
                flush_stage1 <= 1'b1;
            end else if (!rst_n) begin
                flush_stage1 <= 1'b1;
            end else begin
                flush_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: System Reset and Recovery In Progress
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            counter_stage2 <= 8'h00;
            system_reset_stage2 <= 1'b0;
            recovery_stage_stage2 <= 4'h0;
            recovery_in_progress_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            flush_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
            flush_stage2 <= flush_stage1;
            if (flush_stage1) begin
                system_reset_stage2 <= 1'b0;
                recovery_stage_stage2 <= 4'h0;
                recovery_in_progress_stage2 <= 1'b0;
            end else begin
                // Optimized state/action mapping
                system_reset_stage2 <= (state_stage1 == RESET) && !(counter_stage1 == 8'hFF);
                recovery_in_progress_stage2 <= (state_stage1 != IDLE) || (trigger_recovery_stage1);
                recovery_stage_stage2 <= (state_stage1 == IDLE) ? 
                                            (trigger_recovery_stage1 ? 4'h1 : 4'h0) :
                                        (state_stage1 == RESET) ?
                                            (counter_stage1 == 8'hFF ? 4'h2 : 4'h1) :
                                        (state_stage1 == MODULE_RST) ?
                                            4'h2 :
                                        (state_stage1 == MEM_CLEAR) ?
                                            4'h3 :
                                        (state_stage1 == WAIT) ?
                                            4'h4 : 4'h0;
            end
        end
    end

    // Stage 3: Module Reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            counter_stage3 <= 8'h00;
            module_reset_stage3 <= 1'b0;
            recovery_stage_stage3 <= 4'h0;
            recovery_in_progress_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            flush_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            counter_stage3 <= counter_stage2;
            valid_stage3 <= valid_stage2;
            flush_stage3 <= flush_stage2;
            if (flush_stage2) begin
                module_reset_stage3 <= 1'b0;
                recovery_stage_stage3 <= 4'h0;
                recovery_in_progress_stage3 <= 1'b0;
            end else begin
                // Optimized state/action mapping
                module_reset_stage3 <= (state_stage2 == MODULE_RST) && !(counter_stage2 == 8'h7F);
                recovery_in_progress_stage3 <= (state_stage2 == MODULE_RST) ? 1'b1 : recovery_in_progress_stage2;
                recovery_stage_stage3 <= (state_stage2 == MODULE_RST) ?
                                            (counter_stage2 == 8'h7F ? 4'h3 : 4'h2) :
                                        recovery_stage_stage2;
            end
        end
    end

    // Stage 4: Memory Clear
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4 <= IDLE;
            counter_stage4 <= 8'h00;
            memory_clear_stage4 <= 1'b0;
            recovery_stage_stage4 <= 4'h0;
            recovery_in_progress_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
            flush_stage4 <= 1'b0;
        end else begin
            state_stage4 <= state_stage3;
            counter_stage4 <= counter_stage3;
            valid_stage4 <= valid_stage3;
            flush_stage4 <= flush_stage3;
            if (flush_stage3) begin
                memory_clear_stage4 <= 1'b0;
                recovery_stage_stage4 <= 4'h0;
                recovery_in_progress_stage4 <= 1'b0;
            end else begin
                // Optimized state/action mapping
                memory_clear_stage4 <= (state_stage3 == MEM_CLEAR) && !(counter_stage3 == 8'h3F);
                recovery_in_progress_stage4 <= 
                    (state_stage3 == WAIT) ? (counter_stage3 != 8'hFF) :
                    (state_stage3 == MEM_CLEAR) ? 1'b1 :
                    recovery_in_progress_stage3;
                recovery_stage_stage4 <= 
                    (state_stage3 == MEM_CLEAR) ? (counter_stage3 == 8'h3F ? 4'h4 : 4'h3) :
                    (state_stage3 == WAIT) ? (counter_stage3 == 8'hFF ? 4'h0 : 4'h4) :
                    recovery_stage_stage3;
            end
        end
    end

    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovery_stage <= 4'h0;
            recovery_in_progress <= 1'b0;
            system_reset <= 1'b0;
            module_reset <= 1'b0;
            memory_clear <= 1'b0;
        end else begin
            recovery_stage <= recovery_stage_stage4;
            recovery_in_progress <= recovery_in_progress_stage4;
            system_reset <= system_reset_stage2;
            module_reset <= module_reset_stage3;
            memory_clear <= memory_clear_stage4;
        end
    end

endmodule