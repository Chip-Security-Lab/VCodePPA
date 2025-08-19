module usb_remote_wakeup(
    input wire clk,
    input wire rst_n,
    input wire suspend_state,
    input wire remote_wakeup_enabled,
    input wire wakeup_request,
    output reg dp_drive,
    output reg dm_drive,
    output reg wakeup_active,
    output reg [2:0] wakeup_state
);
    // Wakeup state machine states
    localparam IDLE = 3'd0;
    localparam RESUME_K = 3'd1;
    localparam RESUME_DONE = 3'd2;
    
    reg [15:0] k_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup_state <= IDLE;
            dp_drive <= 1'b0;
            dm_drive <= 1'b0;
            wakeup_active <= 1'b0;
            k_counter <= 16'd0;
        end else begin
            case (wakeup_state)
                IDLE: begin
                    if (suspend_state && remote_wakeup_enabled && wakeup_request) begin
                        wakeup_state <= RESUME_K;
                        // Drive K state (dp=0, dm=1)
                        dp_drive <= 1'b0;
                        dm_drive <= 1'b1;
                        wakeup_active <= 1'b1;
                        k_counter <= 16'd0;
                    end else begin
                        dp_drive <= 1'b0;
                        dm_drive <= 1'b0;
                        wakeup_active <= 1'b0;
                    end
                end
                RESUME_K: begin
                    k_counter <= k_counter + 16'd1;
                    // Drive K state for 1-15ms per USB spec
                    if (k_counter >= 16'd50000) begin // ~1ms at 48MHz
                        wakeup_state <= RESUME_DONE;
                        // Stop driving
                        dp_drive <= 1'b0;
                        dm_drive <= 1'b0;
                    end
                end
                RESUME_DONE: begin
                    wakeup_active <= 1'b0;
                    if (!suspend_state)
                        wakeup_state <= IDLE;
                end
            endcase
        end
    end
endmodule