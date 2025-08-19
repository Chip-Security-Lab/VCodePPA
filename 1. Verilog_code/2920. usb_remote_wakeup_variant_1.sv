//SystemVerilog
module usb_remote_wakeup(
    input wire clk,
    input wire rst_n,
    // Input interface with valid/ready handshake
    input wire suspend_state,
    input wire remote_wakeup_enabled,
    input wire wakeup_request,
    input wire input_valid,
    output wire input_ready,
    // Output interface with valid/ready handshake
    output reg dp_drive,
    output reg dm_drive,
    output reg wakeup_active,
    output reg [2:0] wakeup_state,
    output reg output_valid,
    input wire output_ready
);
    // Wakeup state machine states
    localparam IDLE = 3'd0;
    localparam RESUME_K = 3'd1;
    localparam RESUME_DONE = 3'd2;
    localparam WAIT_OUTPUT_READY = 3'd3;
    
    reg [15:0] k_counter;
    reg input_data_captured;
    reg suspend_state_reg;
    reg remote_wakeup_enabled_reg;
    reg wakeup_request_reg;
    
    // Pre-compute next state logic
    reg [2:0] next_wakeup_state;
    reg next_dp_drive;
    reg next_dm_drive;
    reg next_wakeup_active;
    reg [15:0] next_k_counter;
    reg next_output_valid;
    reg next_input_data_captured;
    
    // Handshake signals
    assign input_ready = (wakeup_state == IDLE || wakeup_state == RESUME_DONE) && !input_data_captured;
    
    // Input data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            suspend_state_reg <= 1'b0;
            remote_wakeup_enabled_reg <= 1'b0;
            wakeup_request_reg <= 1'b0;
            input_data_captured <= 1'b0;
        end else if (input_valid && input_ready) begin
            suspend_state_reg <= suspend_state;
            remote_wakeup_enabled_reg <= remote_wakeup_enabled;
            wakeup_request_reg <= wakeup_request;
            input_data_captured <= 1'b1;
        end else if (next_wakeup_state == IDLE && wakeup_state != IDLE) begin
            input_data_captured <= 1'b0;
        end
    end
    
    // Combinational logic for next state calculation
    always @(*) begin
        // Default: maintain current state
        next_wakeup_state = wakeup_state;
        next_dp_drive = dp_drive;
        next_dm_drive = dm_drive;
        next_wakeup_active = wakeup_active;
        next_k_counter = k_counter;
        next_output_valid = output_valid;
        next_input_data_captured = input_data_captured;
        
        case (wakeup_state)
            IDLE: begin
                next_output_valid = 1'b0;
                if (input_data_captured && suspend_state_reg && remote_wakeup_enabled_reg && wakeup_request_reg) begin
                    next_wakeup_state = RESUME_K;
                    // Drive K state (dp=0, dm=1)
                    next_dp_drive = 1'b0;
                    next_dm_drive = 1'b1;
                    next_wakeup_active = 1'b1;
                    next_k_counter = 16'd0;
                end else begin
                    next_dp_drive = 1'b0;
                    next_dm_drive = 1'b0;
                    next_wakeup_active = 1'b0;
                end
            end
            
            RESUME_K: begin
                next_k_counter = k_counter + 16'd1;
                // Drive K state for 1-15ms per USB spec
                if (k_counter >= 16'd50000) begin // ~1ms at 48MHz
                    next_wakeup_state = WAIT_OUTPUT_READY;
                    // Stop driving
                    next_dp_drive = 1'b0;
                    next_dm_drive = 1'b0;
                    next_output_valid = 1'b1;
                end
            end
            
            WAIT_OUTPUT_READY: begin
                if (output_ready) begin
                    next_wakeup_state = RESUME_DONE;
                    next_output_valid = 1'b0;
                end
            end
            
            RESUME_DONE: begin
                next_wakeup_active = 1'b0;
                if (!suspend_state_reg)
                    next_wakeup_state = IDLE;
            end
            
            default: next_wakeup_state = IDLE;
        endcase
    end
    
    // Sequential logic with retimed registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup_state <= IDLE;
            dp_drive <= 1'b0;
            dm_drive <= 1'b0;
            wakeup_active <= 1'b0;
            k_counter <= 16'd0;
            output_valid <= 1'b0;
        end else begin
            wakeup_state <= next_wakeup_state;
            dp_drive <= next_dp_drive;
            dm_drive <= next_dm_drive;
            wakeup_active <= next_wakeup_active;
            k_counter <= next_k_counter;
            output_valid <= next_output_valid;
        end
    end
endmodule