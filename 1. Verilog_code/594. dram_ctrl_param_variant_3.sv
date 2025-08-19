//SystemVerilog
module dram_ctrl_param #(
    parameter tRCD = 3,
    parameter tRP = 2,
    parameter tRAS = 5
)(
    input clk,
    input reset,
    input refresh_req,
    output reg refresh_ack
);

    localparam IDLE = 2'd0,
               REFRESH_DELAY = 2'd1,
               REFRESH_ACTIVE = 2'd2;
    
    reg [1:0] refresh_state;
    reg [1:0] refresh_state_buf;
    reg [7:0] refresh_counter;
    reg [7:0] refresh_counter_buf;
    reg refresh_req_sync;
    reg refresh_ack_buf;
    
    // Synchronize refresh request
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            refresh_req_sync <= 0;
        end else begin
            refresh_req_sync <= refresh_req;
        end
    end
    
    // Main state machine with buffered signals
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            refresh_state <= IDLE;
            refresh_state_buf <= IDLE;
            refresh_ack <= 0;
            refresh_ack_buf <= 0;
            refresh_counter <= 0;
            refresh_counter_buf <= 0;
        end else begin
            // Buffer current state
            refresh_state_buf <= refresh_state;
            refresh_counter_buf <= refresh_counter;
            refresh_ack_buf <= refresh_ack;
            
            // IDLE state transitions
            if(refresh_state_buf == IDLE && refresh_req_sync) begin
                refresh_state <= REFRESH_DELAY;
                refresh_counter <= tRCD;
                refresh_ack <= 0;
            end
            else if(refresh_state_buf == IDLE) begin
                refresh_ack <= 0;
            end
            
            // REFRESH_DELAY state transitions
            if(refresh_state_buf == REFRESH_DELAY && refresh_counter_buf == 0) begin
                refresh_state <= REFRESH_ACTIVE;
                refresh_counter <= tRAS;
            end
            else if(refresh_state_buf == REFRESH_DELAY) begin
                refresh_counter <= refresh_counter_buf - 1;
            end
            
            // REFRESH_ACTIVE state transitions
            if(refresh_state_buf == REFRESH_ACTIVE && refresh_counter_buf == 0) begin
                refresh_state <= IDLE;
                refresh_ack <= 1;
            end
            else if(refresh_state_buf == REFRESH_ACTIVE) begin
                refresh_counter <= refresh_counter_buf - 1;
            end
            
            // Default state handling
            if(refresh_state_buf != IDLE && refresh_state_buf != REFRESH_DELAY && refresh_state_buf != REFRESH_ACTIVE) begin
                refresh_state <= IDLE;
            end
        end
    end
endmodule