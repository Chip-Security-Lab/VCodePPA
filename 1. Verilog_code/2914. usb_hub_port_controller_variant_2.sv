//SystemVerilog
// USB Hub Port Controller - Top Level Module
module usb_hub_port_controller(
    input wire clk_i, rst_n_i,
    input wire port_connected_i,
    input wire port_reset_i,
    input wire port_suspend_i,
    input wire downstream_j_state_i,
    input wire downstream_k_state_i,
    input wire downstream_se0_i,
    input wire upstream_token_i,
    output wire port_enabled_o,
    output wire port_powered_o,
    output wire port_lowspeed_o,
    output wire port_highspeed_o,
    output wire [1:0] port_status_change_o,
    output wire [1:0] port_state_o
);
    // Port states
    localparam DISABLED = 2'b00;
    localparam RESETTING = 2'b01;
    localparam ENABLED = 2'b10;
    localparam SUSPENDED = 2'b11;
    
    // Internal signals for connecting modules
    wire [15:0] reset_count;
    wire next_powered;
    wire next_lowspeed;
    wire next_enabled;
    wire [1:0] next_state;
    wire [1:0] next_status_change;
    wire [15:0] next_reset_count;
    
    // Instantiate next state logic module
    port_state_controller state_ctrl (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .port_connected_i(port_connected_i),
        .port_reset_i(port_reset_i),
        .port_suspend_i(port_suspend_i),
        .downstream_j_state_i(downstream_j_state_i),
        .downstream_k_state_i(downstream_k_state_i),
        .downstream_se0_i(downstream_se0_i),
        .upstream_token_i(upstream_token_i),
        .current_state_i(port_state_o),
        .current_powered_i(port_powered_o),
        .current_lowspeed_i(port_lowspeed_o),
        .current_enabled_i(port_enabled_o),
        .current_status_change_i(port_status_change_o),
        .current_reset_count_i(reset_count),
        .next_state_o(next_state),
        .next_powered_o(next_powered),
        .next_lowspeed_o(next_lowspeed),
        .next_enabled_o(next_enabled),
        .next_status_change_o(next_status_change),
        .next_reset_count_o(next_reset_count)
    );
    
    // Instantiate register module
    port_register_bank reg_bank (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .next_state_i(next_state),
        .next_enabled_i(next_enabled),
        .next_powered_i(next_powered),
        .next_lowspeed_i(next_lowspeed),
        .next_status_change_i(next_status_change),
        .next_reset_count_i(next_reset_count),
        .port_state_o(port_state_o),
        .port_enabled_o(port_enabled_o),
        .port_powered_o(port_powered_o),
        .port_lowspeed_o(port_lowspeed_o),
        .port_highspeed_o(port_highspeed_o),
        .port_status_change_o(port_status_change_o),
        .reset_count_o(reset_count)
    );
    
endmodule

// State Controller Module - Handles all state transition logic
module port_state_controller(
    input wire clk_i, rst_n_i,
    input wire port_connected_i,
    input wire port_reset_i,
    input wire port_suspend_i,
    input wire downstream_j_state_i,
    input wire downstream_k_state_i,
    input wire downstream_se0_i,
    input wire upstream_token_i,
    input wire [1:0] current_state_i,
    input wire current_powered_i,
    input wire current_lowspeed_i,
    input wire current_enabled_i,
    input wire [1:0] current_status_change_i,
    input wire [15:0] current_reset_count_i,
    output reg [1:0] next_state_o,
    output reg next_powered_o,
    output reg next_lowspeed_o,
    output reg next_enabled_o,
    output reg [1:0] next_status_change_o,
    output reg [15:0] next_reset_count_o
);
    // Port states
    localparam DISABLED = 2'b00;
    localparam RESETTING = 2'b01;
    localparam ENABLED = 2'b10;
    localparam SUSPENDED = 2'b11;
    
    // State transition logic
    always @(*) begin
        // Default: maintain current values
        next_state_o = current_state_i;
        next_powered_o = current_powered_i;
        next_lowspeed_o = current_lowspeed_i;
        next_enabled_o = current_enabled_i;
        next_status_change_o = current_status_change_i;
        next_reset_count_o = current_reset_count_i;
        
        case (current_state_i)
            DISABLED: begin
                if (port_connected_i) begin
                    next_powered_o = 1'b1;
                    next_status_change_o[0] = 1'b1; // Connection change
                    next_lowspeed_o = downstream_k_state_i;
                    
                    if (port_reset_i) begin
                        next_state_o = RESETTING;
                        next_reset_count_o = 16'd0;
                    end
                end
            end
            
            RESETTING: begin
                next_reset_count_o = current_reset_count_i + 16'd1;
                
                // Reset timing threshold check
                if (current_reset_count_i >= 16'd5000) begin // ~10ms at 48MHz
                    next_state_o = ENABLED;
                    next_enabled_o = 1'b1;
                    next_status_change_o[1] = 1'b1; // Enable change
                end
            end
            
            // Other states would be implemented here
            default: begin
                // Maintain default values
            end
        endcase
    end
endmodule

// Register Bank Module - Handles all sequential logic
module port_register_bank(
    input wire clk_i, rst_n_i,
    input wire [1:0] next_state_i,
    input wire next_enabled_i,
    input wire next_powered_i,
    input wire next_lowspeed_i,
    input wire [1:0] next_status_change_i,
    input wire [15:0] next_reset_count_i,
    output reg [1:0] port_state_o,
    output reg port_enabled_o,
    output reg port_powered_o,
    output reg port_lowspeed_o,
    output reg port_highspeed_o,
    output reg [1:0] port_status_change_o,
    output reg [15:0] reset_count_o
);
    // Sequential logic for all registers
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            // Reset all registers to initial values
            port_state_o <= 2'b00; // DISABLED
            port_enabled_o <= 1'b0;
            port_powered_o <= 1'b0;
            port_lowspeed_o <= 1'b0;
            port_highspeed_o <= 1'b0;
            port_status_change_o <= 2'b00;
            reset_count_o <= 16'd0;
        end else begin
            // Update all registers with next values
            port_state_o <= next_state_i;
            port_enabled_o <= next_enabled_i;
            port_powered_o <= next_powered_i;
            port_lowspeed_o <= next_lowspeed_i;
            port_status_change_o <= next_status_change_i;
            reset_count_o <= next_reset_count_i;
            // Note: port_highspeed_o is maintained at 0 in this implementation
        end
    end
endmodule