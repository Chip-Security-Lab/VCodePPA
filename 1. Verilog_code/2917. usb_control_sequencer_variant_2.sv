//SystemVerilog
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
    output reg [6:0] control_state, // One-hot encoded state
    output reg need_data_out,
    output reg need_data_in,
    output reg need_status_in,
    output reg need_status_out,
    output reg transfer_complete
);
    // Control transfer states (one-hot encoding)
    localparam IDLE       = 7'b0000001;
    localparam SETUP      = 7'b0000010;
    localparam DATA_OUT   = 7'b0000100;
    localparam DATA_IN    = 7'b0001000;
    localparam STATUS_OUT = 7'b0010000;
    localparam STATUS_IN  = 7'b0100000;
    localparam COMPLETE   = 7'b1000000;
    
    // Direction indicator
    wire is_host_to_device;
    assign is_host_to_device = (bmRequestType[7] == 1'b0);
    
    // State machine control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_state <= IDLE;
        end else begin
            case (control_state)
                IDLE: begin
                    if (setup_received) begin
                        control_state <= SETUP;
                    end
                end
                SETUP: begin
                    if (need_data_out) 
                        control_state <= DATA_OUT;
                    else if (need_data_in) 
                        control_state <= DATA_IN;
                    else if (need_status_in) 
                        control_state <= STATUS_IN;
                    else if (need_status_out) 
                        control_state <= STATUS_OUT;
                end
                DATA_OUT: begin
                    if (data_out_received)
                        control_state <= need_status_in ? STATUS_IN : COMPLETE;
                end
                DATA_IN: begin
                    if (data_in_sent)
                        control_state <= need_status_out ? STATUS_OUT : COMPLETE;
                end
                STATUS_OUT: begin
                    if (status_phase_done)
                        control_state <= COMPLETE;
                end
                STATUS_IN: begin
                    if (status_phase_done)
                        control_state <= COMPLETE;
                end
                COMPLETE: begin
                    control_state <= IDLE;
                end
                default: control_state <= IDLE;
            endcase
        end
    end
    
    // Transfer type configuration logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            need_data_out <= 1'b0;
            need_data_in <= 1'b0;
            need_status_in <= 1'b0;
            need_status_out <= 1'b0;
        end else if (control_state == IDLE && setup_received) begin
            // Configure transfer type based on request type and length
            need_data_out <= is_host_to_device && (wLength > 16'd0);
            need_data_in <= !is_host_to_device && (wLength > 16'd0);
            need_status_in <= is_host_to_device;
            need_status_out <= !is_host_to_device;
        end
    end
    
    // Transfer completion indicator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transfer_complete <= 1'b0;
        end else if (control_state == IDLE) begin
            transfer_complete <= 1'b0;
        end else if (control_state == COMPLETE) begin
            transfer_complete <= 1'b1;
        end
    end
    
endmodule