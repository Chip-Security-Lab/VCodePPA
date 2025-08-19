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

    reg [INT_COUNT-1:0] int_pending;
    reg [2:0] next_int_lut [0:INT_COUNT-1];
    reg [INT_COUNT-1:0] int_pending_next;
    reg [2:0] int_id_next;
    reg int_valid_next;
    reg [INT_COUNT-1:0] int_history_next;
    reg [7:0] int_counts_next [0:INT_COUNT-1];
    reg [2:0] next_int_idx;
    integer i;
    
    // Initialize LUT
    initial begin
        for (i = 0; i < INT_COUNT; i = i + 1)
            next_int_lut[i] = i[2:0];
    end
    
    // Pre-compute next interrupt index
    always @(*) begin
        next_int_idx = 3'd0;
        for (i = INT_COUNT-1; i >= 0; i = i - 1)
            if (int_pending[i]) next_int_idx = i[2:0];
    end
    
    // Combinational logic for next state
    always @(*) begin
        // Default values
        int_pending_next = int_pending | interrupts;
        int_history_next = int_history | interrupts;
        int_id_next = int_id;
        int_valid_next = 1'b0;
        
        // Update interrupt counters
        for (i = 0; i < INT_COUNT; i = i + 1) begin
            int_counts_next[i] = int_counts[i];
            if (interrupts[i] && !int_pending[i])
                int_counts_next[i] = int_counts[i] + 8'd1;
        end
        
        // Debug mode handling
        if (debug_mode) begin
            if (debug_int_override) begin
                int_id_next = debug_force_int;
                int_valid_next = 1'b1;
            end else if (debug_step && |int_pending) begin
                int_id_next = next_int_lut[next_int_idx];
                int_valid_next = 1'b1;
                int_pending_next[int_id] = 1'b0;
            end
        end else if (|int_pending) begin
            // Normal operation
            int_id_next = next_int_lut[next_int_idx];
            int_valid_next = 1'b1;
            int_pending_next[int_id] = 1'b0;
        end
    end
    
    // Sequential logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending <= {INT_COUNT{1'b0}};
            int_id <= 3'd0;
            int_valid <= 1'b0;
            int_history <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i = i + 1)
                int_counts[i] <= 8'd0;
        end else begin
            int_pending <= int_pending_next;
            int_id <= int_id_next;
            int_valid <= int_valid_next;
            int_history <= int_history_next;
            for (i = 0; i < INT_COUNT; i = i + 1)
                int_counts[i] <= int_counts_next[i];
        end
    end
endmodule