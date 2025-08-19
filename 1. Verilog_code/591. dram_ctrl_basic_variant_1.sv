//SystemVerilog
module dram_ctrl_basic #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,
    input cmd_valid,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg ready
);

    // Gray code encoding for states
    localparam IDLE = 3'b000,
               ACTIVE = 3'b001,
               READ = 3'b011,
               PRECHARGE = 3'b010;
    
    reg [2:0] current_state, next_state;
    reg [3:0] timer, next_timer;
    reg [DATA_WIDTH-1:0] next_data_out;
    reg next_ready;
    
    // Pre-compute state conditions
    wire is_idle_state = (current_state == IDLE);
    wire is_active_state = (current_state == ACTIVE);
    wire is_read_state = (current_state == READ);
    wire is_precharge_state = (current_state == PRECHARGE);
    
    // Optimize timer logic
    wire timer_expired = (timer == 0);
    wire timer_not_expired = ~timer_expired;
    wire [3:0] timer_decrement = timer - 1'b1;
    
    // State transition logic
    always @(*) begin
        // Default assignments
        next_state = current_state;
        next_timer = timer;
        next_data_out = data_out;
        next_ready = 1'b0;
        
        // Optimized state machine
        if (is_idle_state) begin
            next_ready = 1'b1;
            if (cmd_valid) begin
                next_state = ACTIVE;
                next_timer = 4'd3;
            end
        end
        else if (is_active_state) begin
            if (timer_expired) begin
                next_state = READ;
            end
            else begin
                next_timer = timer_decrement;
            end
        end
        else if (is_read_state) begin
            next_data_out = {DATA_WIDTH{1'b1}};
            next_state = PRECHARGE;
            next_timer = 4'd2;
        end
        else if (is_precharge_state) begin
            if (timer_expired) begin
                next_state = IDLE;
            end
            else begin
                next_timer = timer_decrement;
            end
        end
        else begin
            next_state = IDLE;
        end
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            timer <= 0;
            data_out <= 0;
            ready <= 1;
        end
        else begin
            current_state <= next_state;
            timer <= next_timer;
            data_out <= next_data_out;
            ready <= next_ready;
        end
    end
endmodule