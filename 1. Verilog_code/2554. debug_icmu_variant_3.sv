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
    wire [2:0] next_int_id;
    wire int_pending_valid;
    
    // Reset logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_pending <= {INT_COUNT{1'b0}};
            int_id <= 3'd0;
            int_valid <= 1'b0;
            int_history <= {INT_COUNT{1'b0}};
            for (integer i = 0; i < INT_COUNT; i=i+1)
                int_counts[i] <= 8'd0;
        end
    end

    // Interrupt history capture
    always @(posedge clk) begin
        if (reset_n)
            int_history <= int_history | interrupts;
    end

    // Interrupt counter update
    always @(posedge clk) begin
        if (reset_n) begin
            for (integer i = 0; i < INT_COUNT; i=i+1) begin
                if (interrupts[i] && !int_pending[i])
                    int_counts[i] <= int_counts[i] + 8'd1;
            end
        end
    end

    // Pending interrupt update
    always @(posedge clk) begin
        if (reset_n)
            int_pending <= int_pending | interrupts;
    end

    // Debug mode interrupt handling
    always @(posedge clk) begin
        if (reset_n && debug_mode) begin
            if (debug_int_override) begin
                int_id <= debug_force_int;
                int_valid <= 1'b1;
            end else if (debug_step && |int_pending) begin
                int_id <= next_int_id;
                int_valid <= 1'b1;
                int_pending[next_int_id] <= 1'b0;
            end else begin
                int_valid <= 1'b0;
            end
        end
    end

    // Normal mode interrupt handling
    always @(posedge clk) begin
        if (reset_n && !debug_mode) begin
            if (|int_pending) begin
                int_id <= next_int_id;
                int_valid <= 1'b1;
                int_pending[next_int_id] <= 1'b0;
            end else begin
                int_valid <= 1'b0;
            end
        end
    end

    // Next interrupt ID calculation
    assign next_int_id = get_next_int(int_pending);

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