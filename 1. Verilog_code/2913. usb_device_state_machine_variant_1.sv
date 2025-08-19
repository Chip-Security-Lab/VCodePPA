//SystemVerilog
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
    // IEEE 1364-2005 Verilog standard
    
    // USB device states per USB spec - one-hot encoding
    localparam POWERED    = 5'b00001;
    localparam DEFAULT    = 5'b00010;
    localparam ADDRESS    = 5'b00100;
    localparam CONFIGURED = 5'b01000;
    localparam SUSPENDED  = 5'b10000;
    
    reg [4:0] current_state;
    reg [4:0] next_state;
    reg [4:0] prev_state;
    reg suspend_pending;
    
    // Convert one-hot state to output binary encoding
    always @(*) begin
        case (current_state)
            POWERED:    device_state = 3'd0;
            DEFAULT:    device_state = 3'd1;
            ADDRESS:    device_state = 3'd2;
            CONFIGURED: device_state = 3'd3;
            SUSPENDED:  device_state = 3'd4;
            default:    device_state = 3'd0;
        endcase
    end
    
    // Optimized state transition logic with priority-based comparisons
    always @(*) begin
        // Default assignment to prevent latches
        next_state = current_state;
        suspend_pending = 1'b0;
        
        // Priority-based state transition logic
        if (bus_reset_detected) begin
            next_state = DEFAULT;
        end else if (current_state == SUSPENDED && resume_detected) begin
            next_state = prev_state;
        end else if (suspend_detected && current_state != SUSPENDED) begin
            next_state = SUSPENDED;
            suspend_pending = 1'b1;
        end else if (!suspend_pending) begin
            // Only process normal state transitions if no suspend is pending
            case (current_state)
                DEFAULT: begin
                    if (address_assigned) 
                        next_state = ADDRESS;
                end
                ADDRESS: begin
                    if (configuration_set) 
                        next_state = CONFIGURED;
                end
                CONFIGURED: begin
                    if (!configuration_set) 
                        next_state = ADDRESS;
                end
                default: begin
                    // No change for other states (POWERED)
                end
            endcase
        end
    end
    
    // Sequential process for state updates with reset prioritization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= POWERED;
            prev_state <= POWERED;
            remote_wakeup_enabled <= 1'b0;
            self_powered <= 1'b0;
            interface_alternate <= 8'h00;
        end else begin
            // Update state registers
            prev_state <= (bus_reset_detected) ? DEFAULT : current_state;
            current_state <= next_state;
            
            // Reset configuration parameters when bus reset occurs
            if (bus_reset_detected) begin
                remote_wakeup_enabled <= 1'b0;
                interface_alternate <= 8'h00;
            end
        end
    end
endmodule