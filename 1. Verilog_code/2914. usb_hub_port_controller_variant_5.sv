//SystemVerilog
module usb_hub_port_controller(
    input wire clk_i, rst_n_i,
    input wire port_connected_i,
    input wire port_reset_i,
    input wire port_suspend_i,
    input wire downstream_j_state_i,
    input wire downstream_k_state_i,
    input wire downstream_se0_i,
    input wire upstream_token_i,
    output reg port_enabled_o,
    output reg port_powered_o,
    output reg port_lowspeed_o,
    output reg port_highspeed_o,
    output reg [1:0] port_status_change_o,
    output reg [1:0] port_state_o
);
    // Port states
    localparam [1:0] DISABLED  = 2'b00;
    localparam [1:0] RESETTING = 2'b01;
    localparam [1:0] ENABLED   = 2'b10;
    localparam [1:0] SUSPENDED = 2'b11;
    
    // Reset timer optimized comparison
    localparam [15:0] RESET_TIMEOUT = 16'd5000; // ~10ms at 48MHz
    reg [15:0] reset_count;
    
    // Optimized comparison using a single subtraction
    wire reset_timeout_reached = ~|({1'b0, RESET_TIMEOUT} - {1'b0, reset_count});
    
    // State transition and control signals
    reg next_port_enabled;
    reg next_port_powered;
    reg next_port_lowspeed;
    reg next_port_highspeed;
    reg [1:0] next_port_status_change;
    reg [1:0] next_port_state;
    reg [15:0] next_reset_count;
    
    // State transition logic
    always @(*) begin
        // Default: maintain current state
        next_port_state = port_state_o;
        next_port_enabled = port_enabled_o;
        next_port_powered = port_powered_o;
        next_port_lowspeed = port_lowspeed_o;
        next_port_highspeed = port_highspeed_o;
        next_port_status_change = port_status_change_o;
        next_reset_count = reset_count;
        
        // Optimized state machine using priority encoding
        case (port_state_o)
            DISABLED: begin
                if (port_connected_i) begin
                    next_port_powered = 1'b1;
                    next_port_status_change[0] = 1'b1; // Connection change
                    next_port_lowspeed = downstream_k_state_i;
                    
                    if (port_reset_i) begin
                        next_port_state = RESETTING;
                        next_reset_count = 16'd0;
                    end
                end
            end
            
            RESETTING: begin
                // Increment counter with saturation to avoid overflow
                next_reset_count = (reset_count < RESET_TIMEOUT) ? reset_count + 16'd1 : RESET_TIMEOUT;
                
                if (reset_timeout_reached) begin
                    next_port_state = ENABLED;
                    next_port_enabled = 1'b1;
                    next_port_status_change[1] = 1'b1; // Enable change
                end
            end
            
            ENABLED, SUSPENDED: begin
                // Empty placeholder for the additional states
                // Note: Keeping this separate for easier expansion
            end
        endcase
    end
    
    // Synchronous state update with async reset
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            port_state_o <= DISABLED;
            port_enabled_o <= 1'b0;
            port_powered_o <= 1'b0;
            port_lowspeed_o <= 1'b0;
            port_highspeed_o <= 1'b0;
            port_status_change_o <= 2'b00;
            reset_count <= 16'd0;
        end else begin
            port_state_o <= next_port_state;
            port_enabled_o <= next_port_enabled;
            port_powered_o <= next_port_powered;
            port_lowspeed_o <= next_port_lowspeed;
            port_highspeed_o <= next_port_highspeed;
            port_status_change_o <= next_port_status_change;
            reset_count <= next_reset_count;
        end
    end
endmodule