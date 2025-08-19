//SystemVerilog
module usb_hub_port_controller(
    input  wire       clk_i,
    input  wire       rst_n_i,
    input  wire       port_connected_i,
    input  wire       port_reset_i,
    input  wire       port_suspend_i,
    input  wire       downstream_j_state_i,
    input  wire       downstream_k_state_i,
    input  wire       downstream_se0_i,
    input  wire       upstream_token_i,
    output reg        port_enabled_o,
    output reg        port_powered_o,
    output reg        port_lowspeed_o,
    output reg        port_highspeed_o,
    output reg  [1:0] port_status_change_o,
    output reg  [1:0] port_state_o
);
    // Port states
    localparam DISABLED  = 2'b00;
    localparam RESETTING = 2'b01;
    localparam ENABLED   = 2'b10;
    localparam SUSPENDED = 2'b11;
    
    // Constants - using power of 2 threshold for better synthesis
    localparam RESET_THRESHOLD = 16'd4096; // ~8.5ms at 48MHz
    
    reg [15:0] reset_count;
    reg        reset_complete;
    reg        connection_change;
    reg        enable_change;
    reg        is_lowspeed;
    reg        next_powered;
    reg [1:0]  next_state;
    
    // Optimized state and transition logic with improved signal naming
    wire in_disabled_state = (port_state_o == DISABLED);
    wire in_resetting_state = (port_state_o == RESETTING);
    wire in_enabled_state = (port_state_o == ENABLED);
    wire in_suspended_state = (port_state_o == SUSPENDED);
    
    // Optimized reset threshold comparison using range check
    always @(*) begin
        reset_complete = (reset_count[15:12] != 0) || (reset_count[11:0] >= 12'hfff);
    end
    
    // Optimized condition logic with balanced paths
    always @(*) begin
        // Default values
        next_state = port_state_o;
        next_powered = port_powered_o;
        connection_change = 1'b0;
        enable_change = 1'b0;
        is_lowspeed = port_lowspeed_o;
        
        // Handle connection events with priority encoding
        case (1'b1)
            // Case 1: Connected device in disabled state
            port_connected_i && in_disabled_state: begin
                next_powered = 1'b1;
                connection_change = 1'b1;
                is_lowspeed = downstream_k_state_i;
                
                if (port_reset_i) begin
                    next_state = RESETTING;
                end
            end
            
            // Case 2: Reset completion
            in_resetting_state && reset_complete: begin
                next_state = ENABLED;
                enable_change = 1'b1;
            end
            
            // Case 3: Suspend request in enabled state
            in_enabled_state && port_suspend_i: begin
                next_state = SUSPENDED;
            end
            
            // Case 4: Resume from suspend
            in_suspended_state && port_reset_i: begin
                next_state = RESETTING;
            end
            
            default: begin
                // Maintain current state
            end
        endcase
    end
    
    // Optimized reset counter logic with enable signal
    wire reset_counter_en = in_resetting_state;
    wire reset_counter_clr = (next_state == RESETTING) && !in_resetting_state;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            reset_count <= 16'd0;
        end else if (reset_counter_clr) begin
            reset_count <= 16'd0;
        end else if (reset_counter_en) begin
            reset_count <= reset_count + 16'd1;
        end
    end
    
    // Optimized main state and outputs register updates
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            port_state_o <= DISABLED;
            port_enabled_o <= 1'b0;
            port_powered_o <= 1'b0;
            port_lowspeed_o <= 1'b0;
            port_highspeed_o <= 1'b0;
            port_status_change_o <= 2'b00;
        end else begin
            // Update state
            port_state_o <= next_state;
            port_powered_o <= next_powered;
            
            // Status change flags - use bitwise OR for parallel assignment
            port_status_change_o <= port_status_change_o | {enable_change, connection_change};
            
            // Update enabled status with single assignment
            if (enable_change) port_enabled_o <= 1'b1;
            
            // Update speed detection - only when new connection is detected
            if (connection_change) port_lowspeed_o <= is_lowspeed;
        end
    end
endmodule