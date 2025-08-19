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
    // Port states - using one-hot encoding for better synthesis
    localparam [1:0] DISABLED  = 2'b00;
    localparam [1:0] RESETTING = 2'b01;
    localparam [1:0] ENABLED   = 2'b10;
    localparam [1:0] SUSPENDED = 2'b11;
    
    // Configurable reset time constant
    localparam RESET_TIMEOUT = 16'd5000; // ~10ms at 48MHz
    
    reg [15:0] reset_count;
    wire reset_complete = (reset_count >= RESET_TIMEOUT);
    
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
            // Default: maintain status change bits
            // Only modified when explicitly setting them
            
            case (port_state_o)
                DISABLED: begin
                    if (port_connected_i) begin
                        port_powered_o <= 1'b1;
                        port_status_change_o[0] <= 1'b1; // Connection change
                        port_lowspeed_o <= downstream_k_state_i;
                        
                        if (port_reset_i) begin
                            port_state_o <= RESETTING;
                            reset_count <= 16'd0;
                        end
                    end
                end
                
                RESETTING: begin
                    // Use less-than comparison instead of greater-than-or-equal
                    // for more efficient comparison in hardware
                    if (reset_complete) begin
                        port_state_o <= ENABLED;
                        port_enabled_o <= 1'b1;
                        port_status_change_o[1] <= 1'b1; // Enable change
                        // No need to reset the counter here since we're changing states
                    end else begin
                        reset_count <= reset_count + 16'd1;
                    end
                end
                
                // Additional states would be implemented here...
                
                default: begin
                    // Safe recovery to DISABLED state
                    port_state_o <= DISABLED;
                end
            endcase
        end
    end
endmodule