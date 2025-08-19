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
    wire [15:0] count_ge_max;
    wire [15:0] timer_ge_limit;
    wire [15:0] coalesce_trigger;
    wire [15:0] next_active;
    wire [15:0] int_ready;
    integer i;

    // Optimized comparison logic using priority encoding
    assign count_ge_max = {16{1'b0}} | (count[0] >= COUNT_MAX) << 0 |
                         (count[1] >= COUNT_MAX) << 1 |
                         (count[2] >= COUNT_MAX) << 2 |
                         (count[3] >= COUNT_MAX) << 3 |
                         (count[4] >= COUNT_MAX) << 4 |
                         (count[5] >= COUNT_MAX) << 5 |
                         (count[6] >= COUNT_MAX) << 6 |
                         (count[7] >= COUNT_MAX) << 7 |
                         (count[8] >= COUNT_MAX) << 8 |
                         (count[9] >= COUNT_MAX) << 9 |
                         (count[10] >= COUNT_MAX) << 10 |
                         (count[11] >= COUNT_MAX) << 11 |
                         (count[12] >= COUNT_MAX) << 12 |
                         (count[13] >= COUNT_MAX) << 13 |
                         (count[14] >= COUNT_MAX) << 14 |
                         (count[15] >= COUNT_MAX) << 15;
                         
    assign timer_ge_limit = {16{1'b0}} | (timer[0] >= TIME_LIMIT) << 0 |
                           (timer[1] >= TIME_LIMIT) << 1 |
                           (timer[2] >= TIME_LIMIT) << 2 |
                           (timer[3] >= TIME_LIMIT) << 3 |
                           (timer[4] >= TIME_LIMIT) << 4 |
                           (timer[5] >= TIME_LIMIT) << 5 |
                           (timer[6] >= TIME_LIMIT) << 6 |
                           (timer[7] >= TIME_LIMIT) << 7 |
                           (timer[8] >= TIME_LIMIT) << 8 |
                           (timer[9] >= TIME_LIMIT) << 9 |
                           (timer[10] >= TIME_LIMIT) << 10 |
                           (timer[11] >= TIME_LIMIT) << 11 |
                           (timer[12] >= TIME_LIMIT) << 12 |
                           (timer[13] >= TIME_LIMIT) << 13 |
                           (timer[14] >= TIME_LIMIT) << 14 |
                           (timer[15] >= TIME_LIMIT) << 15;
                           
    assign coalesce_trigger = count_ge_max | timer_ge_limit;
    assign int_ready = int_pending & ~int_active;
    assign next_active = int_ready & coalesce_trigger;

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
                    end
                end
                // Update active status and coalescing status in parallel
                int_active <= int_active | next_active;
                coalesc_status <= coalesc_status | next_active;
            end
            
            // Generate interrupt if any active and not currently servicing
            if (!int_valid && |int_active) begin
                int_id <= priority_encoder(int_active);
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
    
    // Optimized priority encoder function
    function [3:0] priority_encoder;
        input [15:0] active;
        begin
            priority_encoder = 4'h0;
            if (active[0]) priority_encoder = 4'h0;
            else if (active[1]) priority_encoder = 4'h1;
            else if (active[2]) priority_encoder = 4'h2;
            else if (active[3]) priority_encoder = 4'h3;
            else if (active[4]) priority_encoder = 4'h4;
            else if (active[5]) priority_encoder = 4'h5;
            else if (active[6]) priority_encoder = 4'h6;
            else if (active[7]) priority_encoder = 4'h7;
            else if (active[8]) priority_encoder = 4'h8;
            else if (active[9]) priority_encoder = 4'h9;
            else if (active[10]) priority_encoder = 4'ha;
            else if (active[11]) priority_encoder = 4'hb;
            else if (active[12]) priority_encoder = 4'hc;
            else if (active[13]) priority_encoder = 4'hd;
            else if (active[14]) priority_encoder = 4'he;
            else if (active[15]) priority_encoder = 4'hf;
        end
    endfunction

endmodule