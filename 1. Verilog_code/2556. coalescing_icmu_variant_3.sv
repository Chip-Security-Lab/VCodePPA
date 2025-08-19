//SystemVerilog
module coalescing_icmu #(
    parameter COUNT_MAX = 8,
    parameter TIME_LIMIT = 200
)(
    input clk, rst_n,
    input [15:0] interrupts,
    input tick_10us,
    output reg [15:0] coalesc_status,
    output reg [3:0] int_id,
    output reg int_valid,
    input int_processed
);
    reg [15:0] int_pending;
    reg [15:0] int_active;
    reg [7:0] count [0:15];
    reg [7:0] timer [0:15];
    reg [15:0] int_pending_next;
    reg [15:0] int_active_next;
    reg [7:0] count_next [0:15];
    reg [7:0] timer_next [0:15];
    reg [3:0] int_id_next;
    reg int_valid_next;
    reg [15:0] coalesc_status_next;
    reg [15:0] int_active_pipe;
    reg [3:0] int_id_pipe;
    reg int_valid_pipe;
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_pending <= 16'h0000;
            int_active <= 16'h0000;
            coalesc_status <= 16'h0000;
            int_valid <= 1'b0;
            int_id <= 4'h0;
            int_active_pipe <= 16'h0000;
            int_id_pipe <= 4'h0;
            int_valid_pipe <= 1'b0;
            
            for (i = 0; i < 16; i=i+1) begin
                count[i] <= 8'h00;
                timer[i] <= 8'h00;
            end
        end else begin
            // Pipeline stage 1: Update pending interrupts and process timers
            int_pending_next <= int_pending | interrupts;
            
            for (i = 0; i < 16; i=i+1) begin
                // Flattened if-else structure for timer and count updates
                if (tick_10us && int_pending[i] && !int_active[i] && interrupts[i]) begin
                    count_next[i] <= count[i] + 8'd1;
                    timer_next[i] <= timer[i] + 8'd1;
                end else if (tick_10us && int_pending[i] && !int_active[i]) begin
                    count_next[i] <= count[i];
                    timer_next[i] <= timer[i] + 8'd1;
                end else begin
                    count_next[i] <= count[i];
                    timer_next[i] <= timer[i];
                end
            end
            
            // Pipeline stage 2: Check coalescing conditions
            int_active_next <= int_active;
            coalesc_status_next <= coalesc_status;
            
            for (i = 0; i < 16; i=i+1) begin
                // Flattened if-else structure for coalescing conditions
                if (tick_10us && int_pending[i] && !int_active[i] && 
                    (count_next[i] >= COUNT_MAX || timer_next[i] >= TIME_LIMIT)) begin
                    int_active_next[i] <= 1'b1;
                    coalesc_status_next[i] <= 1'b1;
                end
            end
            
            // Pipeline stage 3: Generate interrupt
            int_active_pipe <= int_active_next;
            int_valid_pipe <= !int_valid && |int_active_next;
            int_id_pipe <= find_next(int_active_next);
            
            // Pipeline stage 4: Process interrupts
            int_active <= int_active_pipe;
            int_valid <= int_valid_pipe;
            int_id <= int_id_pipe;
            coalesc_status <= coalesc_status_next;
            int_pending <= int_pending_next;
            
            for (i = 0; i < 16; i=i+1) begin
                count[i] <= count_next[i];
                timer[i] <= timer_next[i];
            end
            
            if (int_processed) begin
                int_active[int_id] <= 1'b0;
                int_pending[int_id] <= 1'b0;
                coalesc_status[int_id] <= 1'b0;
                count[int_id] <= 8'h00;
                timer[int_id] <= 8'h00;
                int_valid <= 1'b0;
            end
        end
    end
    
    function [3:0] find_next;
        input [15:0] active;
        reg [3:0] result;
        integer j;
        begin
            result = 4'h0;
            for (j = 0; j < 16; j=j+1)
                if (active[j]) result = j[3:0];
            find_next = result;
        end
    endfunction
endmodule