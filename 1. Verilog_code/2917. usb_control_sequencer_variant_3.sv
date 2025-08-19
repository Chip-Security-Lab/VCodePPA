//SystemVerilog
module usb_control_sequencer(
    input wire clk,
    input wire rst_n,
    
    // Setup phase signals with valid-ready handshake
    input wire setup_valid,
    output reg setup_ready,
    input wire [7:0] bmRequestType,
    input wire [7:0] bRequest,
    input wire [15:0] wValue,
    input wire [15:0] wIndex,
    input wire [15:0] wLength,
    
    // Data phase signals with valid-ready handshake
    input wire data_out_valid,
    output reg data_out_ready,
    input wire data_in_ready,
    output reg data_in_valid,
    
    // Status phase signals with valid-ready handshake
    input wire status_in_ready,
    output reg status_in_valid,
    input wire status_out_valid,
    output reg status_out_ready,
    
    // Control state and completion signals
    output reg [2:0] control_state,
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
    
    // Direction determination
    wire is_host_to_device;
    assign is_host_to_device = (bmRequestType[7] == 1'b0);
    
    // Internal flags for tracking phase requirements
    reg need_data_out;
    reg need_data_in;
    reg need_status_in;
    reg need_status_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            control_state <= IDLE;
            need_data_out <= 1'b0;
            need_data_in <= 1'b0;
            need_status_in <= 1'b0;
            need_status_out <= 1'b0;
            transfer_complete <= 1'b0;
            
            // Reset handshake signals
            setup_ready <= 1'b1;
            data_out_ready <= 1'b0;
            data_in_valid <= 1'b0;
            status_in_valid <= 1'b0;
            status_out_ready <= 1'b0;
        end else begin
            // Default assignments
            setup_ready <= setup_ready;
            data_out_ready <= data_out_ready;
            data_in_valid <= data_in_valid;
            status_in_valid <= status_in_valid;
            status_out_ready <= status_out_ready;
            control_state <= control_state;
            transfer_complete <= transfer_complete;
            
            // Flattened control structure with combined conditions
            if (control_state == IDLE) begin
                transfer_complete <= 1'b0;
                setup_ready <= 1'b1;
                
                if (setup_valid && setup_ready) begin
                    control_state <= SETUP;
                    setup_ready <= 1'b0;
                    need_data_out <= is_host_to_device && (wLength > 16'd0);
                    need_data_in <= !is_host_to_device && (wLength > 16'd0);
                    need_status_in <= is_host_to_device;
                    need_status_out <= !is_host_to_device;
                end
            end
            
            if (control_state == SETUP && need_data_out) begin
                control_state <= DATA_OUT;
                data_out_ready <= 1'b1;
            end
            
            if (control_state == SETUP && need_data_in) begin
                control_state <= DATA_IN;
                data_in_valid <= 1'b1;
            end
            
            if (control_state == SETUP && need_status_in) begin
                control_state <= STATUS_IN;
                status_in_valid <= 1'b1;
            end
            
            if (control_state == SETUP && need_status_out) begin
                control_state <= STATUS_OUT;
                status_out_ready <= 1'b1;
            end
            
            if (control_state == DATA_OUT && data_out_valid && data_out_ready) begin
                data_out_ready <= 1'b0;
                if (need_status_in) begin
                    control_state <= STATUS_IN;
                    status_in_valid <= 1'b1;
                end
            end
            
            if (control_state == DATA_IN && data_in_valid && data_in_ready) begin
                data_in_valid <= 1'b0;
                if (need_status_out) begin
                    control_state <= STATUS_OUT;
                    status_out_ready <= 1'b1;
                end
            end
            
            if (control_state == STATUS_OUT && status_out_valid && status_out_ready) begin
                status_out_ready <= 1'b0;
                control_state <= COMPLETE;
                transfer_complete <= 1'b1;
            end
            
            if (control_state == STATUS_IN && status_in_valid && status_in_ready) begin
                status_in_valid <= 1'b0;
                control_state <= COMPLETE;
                transfer_complete <= 1'b1;
            end
            
            if (control_state == COMPLETE) begin
                control_state <= IDLE;
                setup_ready <= 1'b1;
            end
            
            if (control_state > COMPLETE) begin
                control_state <= IDLE;
            end
        end
    end
endmodule