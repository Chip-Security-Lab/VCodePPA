//SystemVerilog
module ITRC_FSM_MultiEvent #(
    parameter EVENTS = 4
)(
    input clk,
    input rst_n,
    input [EVENTS-1:0] event_in,
    output reg [EVENTS-1:0] ack
);

    // State definitions
    parameter IDLE = 2'b00;
    parameter CAPTURE = 2'b01;
    parameter PROCESS = 2'b10;
    
    // Pipeline registers
    reg [1:0] curr_state_stage1;
    reg [1:0] curr_state_stage2;
    reg [EVENTS-1:0] event_in_stage1;
    reg [EVENTS-1:0] event_in_stage2;
    reg [EVENTS-1:0] ack_stage1;
    reg [EVENTS-1:0] ack_stage2;
    
    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state_stage1 <= IDLE;
        end else begin
            case(curr_state_stage1)
                IDLE: if (|event_in) curr_state_stage1 <= CAPTURE;
                CAPTURE: curr_state_stage1 <= PROCESS;
                PROCESS: if (!(|event_in)) curr_state_stage1 <= IDLE;
                default: curr_state_stage1 <= IDLE;
            endcase
        end
    end

    // Event input pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_in_stage1 <= 0;
            event_in_stage2 <= 0;
        end else begin
            event_in_stage1 <= event_in;
            event_in_stage2 <= event_in_stage1;
        end
    end

    // Acknowledge generation for stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack_stage1 <= 0;
        end else begin
            case(curr_state_stage1)
                CAPTURE: ack_stage1 <= event_in;
                PROCESS: ack_stage1 <= 0;
                default: ack_stage1 <= 0;
            endcase
        end
    end

    // Stage 2 state and acknowledge pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state_stage2 <= IDLE;
            ack_stage2 <= 0;
        end else begin
            curr_state_stage2 <= curr_state_stage1;
            ack_stage2 <= ack_stage1;
        end
    end
    
    // Output assignment
    always @(*) begin
        ack = ack_stage2;
    end

endmodule