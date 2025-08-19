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
    integer i;
    
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
            // Update pending interrupts
            int_pending <= int_pending | interrupts;
            
            // Process tick for timers
            if (tick_10us) begin
                for (i = 0; i < 16; i=i+1) begin
                    if (int_pending[i] && !int_active[i]) begin
                        if (interrupts[i])
                            count[i] <= count[i] + 8'd1;
                        timer[i] <= timer[i] + 8'd1;
                        
                        // Check coalescing conditions
                        if (count[i] >= COUNT_MAX || timer[i] >= TIME_LIMIT) begin
                            int_active[i] <= 1'b1;
                            coalesc_status[i] <= 1'b1;
                        end
                    end
                end
            end
            
            // Generate interrupt if any active and not currently servicing
            if (!int_valid && |int_active) begin
                int_id <= find_next(int_active);
                int_valid <= 1'b1;
            end else if (int_processed) begin
                // Clear the processed interrupt
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