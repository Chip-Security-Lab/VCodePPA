//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module usb_control_sequencer(
    input wire clk,
    input wire rst_n,
    input wire setup_received,
    input wire [7:0] bmRequestType,
    input wire [7:0] bRequest,
    input wire [15:0] wValue,
    input wire [15:0] wIndex,
    input wire [15:0] wLength,
    input wire data_out_received,
    input wire data_in_sent,
    input wire status_phase_done,
    output reg [2:0] control_state,
    output reg need_data_out,
    output reg need_data_in,
    output reg need_status_in,
    output reg need_status_out,
    output reg transfer_complete
);
    // Control transfer states
    localparam IDLE = 3'd0;
    localparam SETUP = 3'd1;
    localparam DATA_OUT = 3'd2;
    localparam DATA_IN = 3'd3;
    localparam STATUS_OUT = 3'd4;
    localparam STATUS_IN = 3'd5;
    localparam COMPLETE = 3'd6;
    
    // Pipeline registers for control path optimization
    reg [7:0] bmRequestType_r;
    reg [15:0] wLength_r;
    reg setup_received_r;
    reg data_out_received_r;
    reg data_in_sent_r;
    reg status_phase_done_r;
    
    // Optimized bit extraction for direction detection - pipelined
    wire is_host_to_device_pre = !bmRequestType[7];
    reg is_host_to_device;
    
    // Pre-compute data phase condition using bit reduction - pipelined
    wire has_data_phase_pre = |wLength;
    reg has_data_phase;
    
    // Next state logic - with pipeline registers
    reg [2:0] next_state;
    reg [2:0] next_state_r;
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bmRequestType_r <= 8'h0;
            wLength_r <= 16'h0;
            setup_received_r <= 1'b0;
            data_out_received_r <= 1'b0;
            data_in_sent_r <= 1'b0;
            status_phase_done_r <= 1'b0;
            is_host_to_device <= 1'b0;
            has_data_phase <= 1'b0;
        end else begin
            bmRequestType_r <= bmRequestType;
            wLength_r <= wLength;
            setup_received_r <= setup_received;
            data_out_received_r <= data_out_received;
            data_in_sent_r <= data_in_sent;
            status_phase_done_r <= status_phase_done;
            is_host_to_device <= is_host_to_device_pre;
            has_data_phase <= has_data_phase_pre;
        end
    end
    
    // Next state computation with reduced critical path
    always @(*) begin
        // Default values
        next_state = control_state;
        
        case (control_state)
            IDLE: begin
                if (setup_received_r) begin
                    next_state = SETUP;
                end
            end
            
            SETUP: begin
                if (has_data_phase) begin
                    next_state = is_host_to_device ? DATA_OUT : DATA_IN;
                end else begin
                    next_state = is_host_to_device ? STATUS_IN : STATUS_OUT;
                end
            end
            
            DATA_OUT: begin
                if (data_out_received_r) begin
                    next_state = STATUS_IN;
                end
            end
            
            DATA_IN: begin
                if (data_in_sent_r) begin
                    next_state = STATUS_OUT;
                end
            end
            
            STATUS_OUT: begin
                if (status_phase_done_r) begin
                    next_state = COMPLETE;
                end
            end
            
            STATUS_IN: begin
                if (status_phase_done_r) begin
                    next_state = COMPLETE;
                end
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Pipeline next_state computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_r <= IDLE;
        end else begin
            next_state_r <= next_state;
        end
    end
    
    // Control signal computation registers
    reg need_data_out_pre, need_data_in_pre;
    reg need_status_in_pre, need_status_out_pre;
    reg transfer_complete_pre;
    
    // Pre-compute control signals
    always @(*) begin
        // Default values maintain current state
        need_data_out_pre = need_data_out;
        need_data_in_pre = need_data_in;
        need_status_in_pre = need_status_in;
        need_status_out_pre = need_status_out;
        transfer_complete_pre = transfer_complete;
        
        case (next_state_r)
            IDLE: begin
                need_data_out_pre = 1'b0;
                need_data_in_pre = 1'b0;
                need_status_in_pre = 1'b0;
                need_status_out_pre = 1'b0;
                transfer_complete_pre = 1'b0;
            end
            
            SETUP: begin
                // Split combinational logic to reduce critical path
                need_data_out_pre = is_host_to_device & has_data_phase;
                need_data_in_pre = !is_host_to_device & has_data_phase;
                need_status_in_pre = is_host_to_device;
                need_status_out_pre = !is_host_to_device;
                transfer_complete_pre = 1'b0;
            end
            
            COMPLETE: begin
                transfer_complete_pre = 1'b1;
            end
            
            default: begin
                // Maintain current values for unhandled states
            end
        endcase
    end
    
    // Final sequential update with pipelined control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_state <= IDLE;
            need_data_out <= 1'b0;
            need_data_in <= 1'b0;
            need_status_in <= 1'b0;
            need_status_out <= 1'b0;
            transfer_complete <= 1'b0;
        end else begin
            control_state <= next_state_r;
            need_data_out <= need_data_out_pre;
            need_data_in <= need_data_in_pre;
            need_status_in <= need_status_in_pre;
            need_status_out <= need_status_out_pre;
            transfer_complete <= transfer_complete_pre;
        end
    end
endmodule

`default_nettype wire