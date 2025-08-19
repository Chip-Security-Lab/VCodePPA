//SystemVerilog
// Priority Encoder Module
module priority_encoder #(
    parameter INT_COUNT = 8
)(
    input [INT_COUNT-1:0] int_pending,
    output reg [2:0] selected_int,
    output reg int_found
);
    integer i;
    always @(*) begin
        selected_int = 3'd0;
        int_found = 1'b0;
        for (i = INT_COUNT-1; i >= 0; i=i-1) begin
            if (int_pending[i] && !int_found) begin
                selected_int = i[2:0];
                int_found = 1'b1;
            end
        end
    end
endmodule

// Interrupt History Module
module int_history #(
    parameter INT_COUNT = 8
)(
    input [INT_COUNT-1:0] interrupts,
    input [INT_COUNT-1:0] int_history,
    input [INT_COUNT-1:0] int_pending,
    input [7:0] int_counts [0:INT_COUNT-1],
    output reg [INT_COUNT-1:0] int_history_next,
    output reg [7:0] int_counts_next [0:INT_COUNT-1]
);
    integer i;
    always @(*) begin
        int_history_next = int_history | interrupts;
        for (i = 0; i < INT_COUNT; i=i+1) begin
            int_counts_next[i] = int_counts[i];
            if (interrupts[i] && !int_pending[i])
                int_counts_next[i] = int_counts[i] + 8'd1;
        end
    end
endmodule

// Interrupt Control Module
module int_control #(
    parameter INT_COUNT = 8
)(
    input [INT_COUNT-1:0] int_pending,
    input [2:0] selected_int,
    input int_valid_next,
    output reg [INT_COUNT-1:0] int_pending_next
);
    always @(*) begin
        int_pending_next = int_pending;
        if (int_valid_next)
            int_pending_next[selected_int] = 1'b0;
    end
endmodule

// Debug Control Module
module debug_control #(
    parameter INT_COUNT = 8
)(
    input debug_mode,
    input debug_step,
    input debug_int_override,
    input [2:0] debug_force_int,
    input [INT_COUNT-1:0] int_pending,
    input [2:0] selected_int,
    output reg [2:0] int_id_next,
    output reg int_valid_next
);
    always @(*) begin
        int_id_next = selected_int;
        int_valid_next = 1'b0;
        
        if (debug_mode) begin
            if (debug_int_override) begin
                int_id_next = debug_force_int;
                int_valid_next = 1'b1;
            end else if (debug_step && |int_pending) begin
                int_valid_next = 1'b1;
            end
        end else if (|int_pending) begin
            int_valid_next = 1'b1;
        end
    end
endmodule

// Top Module
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
    // Pipeline stage registers
    reg [INT_COUNT-1:0] int_pending;
    reg [INT_COUNT-1:0] int_pending_next;
    reg [INT_COUNT-1:0] int_history_next;
    reg [7:0] int_counts_next [0:INT_COUNT-1];
    reg [2:0] int_id_next;
    reg int_valid_next;
    
    // Internal signals
    wire [2:0] selected_int;
    wire int_found;
    
    // Module instances
    priority_encoder #(INT_COUNT) pe (
        .int_pending(int_pending),
        .selected_int(selected_int),
        .int_found(int_found)
    );
    
    int_history #(INT_COUNT) hist (
        .interrupts(interrupts),
        .int_history(int_history),
        .int_pending(int_pending),
        .int_counts(int_counts),
        .int_history_next(int_history_next),
        .int_counts_next(int_counts_next)
    );
    
    int_control #(INT_COUNT) ctrl (
        .int_pending(int_pending),
        .selected_int(selected_int),
        .int_valid_next(int_valid_next),
        .int_pending_next(int_pending_next)
    );
    
    debug_control #(INT_COUNT) dbg (
        .debug_mode(debug_mode),
        .debug_step(debug_step),
        .debug_int_override(debug_int_override),
        .debug_force_int(debug_force_int),
        .int_pending(int_pending),
        .selected_int(selected_int),
        .int_id_next(int_id_next),
        .int_valid_next(int_valid_next)
    );
    
    // Sequential logic
    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending <= {INT_COUNT{1'b0}};
            int_id <= 3'd0;
            int_valid <= 1'b0;
            int_history <= {INT_COUNT{1'b0}};
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= 8'd0;
        end else begin
            int_pending <= int_pending_next;
            int_id <= int_id_next;
            int_valid <= int_valid_next;
            int_history <= int_history_next;
            for (i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= int_counts_next[i];
        end
    end
endmodule