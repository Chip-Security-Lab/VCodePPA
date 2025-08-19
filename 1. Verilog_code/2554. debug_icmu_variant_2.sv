//SystemVerilog
module debug_icmu #(
    parameter INT_COUNT = 8
)(
    input clk, reset_n,
    input [INT_COUNT-1:0] interrupts,
    input debug_mode,
    input debug_step,
    input debug_int_override,
    input [2:0] debug_force_int,
    output reg [2:0] int_id,
    output reg int_valid,
    output reg [INT_COUNT-1:0] int_history,
    output reg [7:0] int_counts [0:INT_COUNT-1]
);

    // Stage 1 registers
    reg [INT_COUNT-1:0] int_pending_stage1;
    reg [INT_COUNT-1:0] int_history_stage1;
    reg [7:0] int_counts_stage1 [0:INT_COUNT-1];
    reg [INT_COUNT-1:0] interrupts_stage1;
    reg debug_mode_stage1;
    reg debug_step_stage1;
    reg debug_int_override_stage1;
    reg [2:0] debug_force_int_stage1;
    
    // Stage 2 registers
    reg [INT_COUNT-1:0] int_pending_stage2;
    reg [INT_COUNT-1:0] int_history_stage2;
    reg [7:0] int_counts_stage2 [0:INT_COUNT-1];
    reg [2:0] int_id_stage2;
    reg int_valid_stage2;
    reg [INT_COUNT-1:0] interrupts_stage2;
    reg debug_mode_stage2;
    reg debug_step_stage2;
    reg debug_int_override_stage2;
    reg [2:0] debug_force_int_stage2;
    
    // Stage 3 registers
    reg [INT_COUNT-1:0] int_pending_stage3;
    reg [INT_COUNT-1:0] int_history_stage3;
    reg [7:0] int_counts_stage3 [0:INT_COUNT-1];
    reg [2:0] int_id_stage3;
    reg int_valid_stage3;
    
    integer i;
    
    // Stage 1: Input sampling and history update
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending_stage1 <= {INT_COUNT{1'b0}};
            int_history_stage1 <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage1[i] <= 8'd0;
            interrupts_stage1 <= {INT_COUNT{1'b0}};
            debug_mode_stage1 <= 1'b0;
            debug_step_stage1 <= 1'b0;
            debug_int_override_stage1 <= 1'b0;
            debug_force_int_stage1 <= 3'd0;
        end else begin
            interrupts_stage1 <= interrupts;
            debug_mode_stage1 <= debug_mode;
            debug_step_stage1 <= debug_step;
            debug_int_override_stage1 <= debug_int_override;
            debug_force_int_stage1 <= debug_force_int;
            
            int_history_stage1 <= int_history | interrupts;
            for (i = 0; i < INT_COUNT; i=i+1) begin
                int_counts_stage1[i] <= interrupts[i] && !int_pending_stage1[i] ? 
                    int_counts_stage1[i] + 8'd1 : int_counts_stage1[i];
            end
            
            int_pending_stage1 <= int_pending_stage1 | interrupts;
        end
    end
    
    // Stage 2: Interrupt processing and priority encoding
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending_stage2 <= {INT_COUNT{1'b0}};
            int_history_stage2 <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage2[i] <= 8'd0;
            int_id_stage2 <= 3'd0;
            int_valid_stage2 <= 1'b0;
            interrupts_stage2 <= {INT_COUNT{1'b0}};
            debug_mode_stage2 <= 1'b0;
            debug_step_stage2 <= 1'b0;
            debug_int_override_stage2 <= 1'b0;
            debug_force_int_stage2 <= 3'd0;
        end else begin
            int_pending_stage2 <= int_pending_stage1;
            int_history_stage2 <= int_history_stage1;
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage2[i] <= int_counts_stage1[i];
            interrupts_stage2 <= interrupts_stage1;
            debug_mode_stage2 <= debug_mode_stage1;
            debug_step_stage2 <= debug_step_stage1;
            debug_int_override_stage2 <= debug_int_override_stage1;
            debug_force_int_stage2 <= debug_force_int_stage1;
            
            case ({debug_mode_stage1, debug_int_override_stage1, debug_step_stage1, |int_pending_stage1})
                4'b1000: begin
                    int_id_stage2 <= 3'd0;
                    int_valid_stage2 <= 1'b0;
                end
                4'b1100: begin
                    int_id_stage2 <= debug_force_int_stage1;
                    int_valid_stage2 <= 1'b1;
                end
                4'b1011: begin
                    int_id_stage2 <= get_next_int(int_pending_stage1);
                    int_valid_stage2 <= 1'b1;
                end
                4'b0001: begin
                    int_id_stage2 <= get_next_int(int_pending_stage1);
                    int_valid_stage2 <= 1'b1;
                end
                default: begin
                    int_id_stage2 <= 3'd0;
                    int_valid_stage2 <= 1'b0;
                end
            endcase
        end
    end
    
    // Stage 3: Output generation and pending update
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending_stage3 <= {INT_COUNT{1'b0}};
            int_history_stage3 <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage3[i] <= 8'd0;
            int_id_stage3 <= 3'd0;
            int_valid_stage3 <= 1'b0;
        end else begin
            int_pending_stage3 <= int_pending_stage2;
            int_history_stage3 <= int_history_stage2;
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts_stage3[i] <= int_counts_stage2[i];
            int_id_stage3 <= int_id_stage2;
            int_valid_stage3 <= int_valid_stage2;
            
            if (int_valid_stage2) begin
                int_pending_stage3[int_id_stage2] <= 1'b0;
            end
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_id <= 3'd0;
            int_valid <= 1'b0;
            int_history <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= 8'd0;
        end else begin
            int_id <= int_id_stage3;
            int_valid <= int_valid_stage3;
            int_history <= int_history_stage3;
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= int_counts_stage3[i];
        end
    end
    
    function [2:0] get_next_int;
        input [INT_COUNT-1:0] pending;
        reg [2:0] result;
        integer j;
        begin
            result = 3'd0;
            for (j = INT_COUNT-1; j >= 0; j=j-1)
                if (pending[j]) result = j[2:0];
            get_next_int = result;
        end
    endfunction
endmodule