module usb_device_state_machine(
    input wire clk, rst_n,
    input wire bus_reset_detected,
    input wire setup_received,
    input wire address_assigned,
    input wire configuration_set,
    input wire suspend_detected,
    input wire resume_detected,
    output reg [2:0] device_state,
    output reg remote_wakeup_enabled,
    output reg self_powered,
    output reg [7:0] interface_alternate
);
    // USB device states per USB spec
    localparam POWERED = 3'd0;
    localparam DEFAULT = 3'd1;
    localparam ADDRESS = 3'd2;
    localparam CONFIGURED = 3'd3;
    localparam SUSPENDED = 3'd4;
    
    reg [2:0] prev_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_state <= POWERED;
            prev_state <= POWERED;
            remote_wakeup_enabled <= 1'b0;
            self_powered <= 1'b0;
            interface_alternate <= 8'h00;
        end else begin
            prev_state <= device_state;
            
            if (bus_reset_detected) begin
                device_state <= DEFAULT;
                remote_wakeup_enabled <= 1'b0;
                interface_alternate <= 8'h00;
            end else if (suspend_detected && device_state != SUSPENDED) begin
                device_state <= SUSPENDED;
            end else if (resume_detected && device_state == SUSPENDED) begin
                device_state <= prev_state;
            end else begin
                case (device_state)
                    DEFAULT: if (address_assigned) device_state <= ADDRESS;
                    ADDRESS: if (configuration_set) device_state <= CONFIGURED;
                    CONFIGURED: if (!configuration_set) device_state <= ADDRESS;
                    default: device_state <= device_state;
                endcase
            end
        end
    end
endmodule