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

    // Pipeline registers
    reg [15:0] int_pending_pipe;
    reg [15:0] int_active_pipe;
    reg [7:0] count_pipe [0:15];
    reg [7:0] timer_pipe [0:15];
    reg [15:0] interrupts_pipe;
    reg tick_10us_pipe;
    reg [15:0] int_active_pipe2;
    reg [3:0] int_id_pipe;
    reg int_valid_pipe;
    reg int_processed_pipe;

    integer i;

    // Pipeline stage 1: Register inputs and current state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_pending_pipe <= 16'h0000;
            int_active_pipe <= 16'h0000;
            interrupts_pipe <= 16'h0000;
            tick_10us_pipe <= 1'b0;
            for (i = 0; i < 16; i=i+1) begin
                count_pipe[i] <= 8'h00;
                timer_pipe[i] <= 8'h00;
            end
        end else begin
            int_pending_pipe <= int_pending;
            int_active_pipe <= int_active;
            interrupts_pipe <= interrupts;
            tick_10us_pipe <= tick_10us;
            for (i = 0; i < 16; i=i+1) begin
                count_pipe[i] <= count[i];
                timer_pipe[i] <= timer[i];
            end
        end
    end

    // Pipeline stage 2: Process timers and update counts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_active_pipe2 <= 16'h0000;
            int_id_pipe <= 4'h0;
            int_valid_pipe <= 1'b0;
            int_processed_pipe <= 1'b0;
        end else begin
            int_active_pipe2 <= int_active_next;
            int_id_pipe <= int_id_next;
            int_valid_pipe <= int_valid_next;
            int_processed_pipe <= int_processed;
        end
    end

    // Pipeline stage 3: Update state registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_pending <= 16'h0000;
            int_active <= 16'h0000;
            coalesc_status <= 16'h0000;
            int_valid <= 1'b0;
            int_id <= 4'h0;
            for (i = 0; i < 16; i=i+1) begin
                count[i] <= 8'h00;
                timer[i] <= 8'h00;
            end
        end else begin
            int_pending <= int_pending_next;
            int_active <= int_active_next;
            coalesc_status <= coalesc_status_next;
            int_valid <= int_valid_next;
            int_id <= int_id_next;
            for (i = 0; i < 16; i=i+1) begin
                count[i] <= count_next[i];
                timer[i] <= timer_next[i];
            end
        end
    end

    // Combinational logic for next state
    always @(*) begin
        int_pending_next = int_pending_pipe | interrupts_pipe;
        int_active_next = int_active_pipe;
        coalesc_status_next = coalesc_status;
        int_valid_next = int_valid_pipe;
        int_id_next = int_id_pipe;
        
        for (i = 0; i < 16; i=i+1) begin
            count_next[i] = count_pipe[i];
            timer_next[i] = timer_pipe[i];
            
            if (tick_10us_pipe && int_pending_pipe[i] && !int_active_pipe[i]) begin
                if (interrupts_pipe[i])
                    count_next[i] = count_pipe[i] + 8'd1;
                timer_next[i] = timer_pipe[i] + 8'd1;
                
                if (count_next[i] >= COUNT_MAX || timer_next[i] >= TIME_LIMIT) begin
                    int_active_next[i] = 1'b1;
                    coalesc_status_next[i] = 1'b1;
                end
            end
        end
        
        if (!int_valid_pipe && |int_active_pipe2) begin
            int_id_next = find_next(int_active_pipe2);
            int_valid_next = 1'b1;
        end else if (int_processed_pipe) begin
            int_active_next[int_id_pipe] = 1'b0;
            int_pending_next[int_id_pipe] = 1'b0;
            coalesc_status_next[int_id_pipe] = 1'b0;
            count_next[int_id_pipe] = 8'h00;
            timer_next[int_id_pipe] = 8'h00;
            int_valid_next = 1'b0;
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