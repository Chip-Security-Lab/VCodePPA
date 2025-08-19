//SystemVerilog
//============================================================================
// USB Remote Wakeup Controller - Top Module with Pipelined Architecture
//============================================================================
module usb_remote_wakeup (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       suspend_state,
    input  wire       remote_wakeup_enabled,
    input  wire       wakeup_request,
    output wire       dp_drive,
    output wire       dm_drive,
    output wire       wakeup_active,
    output wire [2:0] wakeup_state
);

    // Pipeline Stage Signals
    wire       trigger_wakeup_stage1;
    wire       trigger_wakeup_stage2;
    wire       k_state_done_stage1;
    wire       control_dp_stage1;
    wire       control_dm_stage1;
    wire       control_active_stage1;
    wire [2:0] control_state_stage1;
    wire [15:0] k_duration;

    // Pipeline Control Signals
    reg        stage1_valid;
    reg        stage2_valid;
    
    // Constants
    localparam K_DURATION_1MS = 16'd50000;  // ~1ms at 48MHz

    // Stage 1: Wakeup Detection and Pipeline Register
    wakeup_detector_pipelined u_wakeup_detector (
        .clk                  (clk),
        .rst_n                (rst_n),
        .suspend_state        (suspend_state),
        .remote_wakeup_enabled(remote_wakeup_enabled),
        .wakeup_request       (wakeup_request),
        .stage_valid          (stage1_valid),
        .trigger_wakeup       (trigger_wakeup_stage1)
    );

    // Pipeline Registers Stage 1->2
    reg        trigger_wakeup_reg;
    reg        suspend_state_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_wakeup_reg <= 1'b0;
            suspend_state_reg <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            trigger_wakeup_reg <= trigger_wakeup_stage1;
            suspend_state_reg <= suspend_state;
            stage1_valid <= 1'b1;  // Always valid after reset
        end
    end
    
    assign trigger_wakeup_stage2 = trigger_wakeup_reg;

    // Stage 2: K-state Timer Module (Pipelined)
    k_state_timer_pipelined u_k_state_timer (
        .clk                  (clk),
        .rst_n                (rst_n),
        .wakeup_state         (control_state_stage1),
        .k_duration           (K_DURATION_1MS),
        .stage_valid          (stage2_valid),
        .k_state_done         (k_state_done_stage1)
    );

    // Stage 3: Wakeup FSM Controller (Pipelined)
    wakeup_controller_pipelined u_wakeup_controller (
        .clk                  (clk),
        .rst_n                (rst_n),
        .suspend_state        (suspend_state_reg),
        .trigger_wakeup       (trigger_wakeup_stage2),
        .k_state_done         (k_state_done_stage1),
        .stage_valid          (stage2_valid),
        .dp_drive             (control_dp_stage1),
        .dm_drive             (control_dm_stage1),
        .wakeup_active        (control_active_stage1),
        .wakeup_state         (control_state_stage1)
    );

    // Pipeline stage valid control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
        end
    end

    // Output assignments
    assign dp_drive = control_dp_stage1;
    assign dm_drive = control_dm_stage1;
    assign wakeup_active = control_active_stage1;
    assign wakeup_state = control_state_stage1;

endmodule

//============================================================================
// Pipelined Wakeup Detector Module
//============================================================================
module wakeup_detector_pipelined (
    input  wire clk,
    input  wire rst_n,
    input  wire suspend_state,
    input  wire remote_wakeup_enabled,
    input  wire wakeup_request,
    input  wire stage_valid,
    output reg  trigger_wakeup
);
    // Pipeline stage signals
    reg condition_met_stage1;
    
    // Stage 1: Detect condition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            condition_met_stage1 <= 1'b0;
        end else if (stage_valid) begin
            condition_met_stage1 <= suspend_state && remote_wakeup_enabled && wakeup_request;
        end
    end
    
    // Stage 2: Generate trigger
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_wakeup <= 1'b0;
        end else if (stage_valid) begin
            trigger_wakeup <= condition_met_stage1;
        end
    end

endmodule

//============================================================================
// Pipelined K-State Timer Module
//============================================================================
module k_state_timer_pipelined (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] wakeup_state,
    input  wire [15:0] k_duration,
    input  wire       stage_valid,
    output reg        k_state_done
);
    // Wakeup state machine states
    localparam IDLE = 3'd0;
    localparam RESUME_K = 3'd1;
    
    // Pipeline registers
    reg [15:0] k_counter;
    reg [15:0] k_counter_next;
    reg        in_k_state;
    reg        k_state_timeout;
    
    // Stage 1: Determine if in K state and update counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_k_state <= 1'b0;
            k_counter <= 16'd0;
        end else if (stage_valid) begin
            in_k_state <= (wakeup_state == RESUME_K);
            
            if (wakeup_state != RESUME_K) begin
                k_counter <= 16'd0;
            end else begin
                k_counter <= k_counter + 16'd1;
            end
        end
    end
    
    // Stage 2: Determine if K state duration is reached
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_state_timeout <= 1'b0;
        end else if (stage_valid) begin
            k_state_timeout <= (k_counter >= k_duration);
        end
    end
    
    // Stage 3: Generate k_state_done signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_state_done <= 1'b0;
        end else if (stage_valid) begin
            k_state_done <= in_k_state && k_state_timeout;
        end
    end

endmodule

//============================================================================
// Pipelined Wakeup Controller FSM
//============================================================================
module wakeup_controller_pipelined (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       suspend_state,
    input  wire       trigger_wakeup,
    input  wire       k_state_done,
    input  wire       stage_valid,
    output reg        dp_drive,
    output reg        dm_drive,
    output reg        wakeup_active,
    output reg  [2:0] wakeup_state
);
    // Wakeup state machine states
    localparam IDLE = 3'd0;
    localparam RESUME_K = 3'd1;
    localparam RESUME_DONE = 3'd2;
    
    // Pipeline stage registers
    reg [2:0] next_state_stage1;
    reg       dp_drive_stage1;
    reg       dm_drive_stage1;
    reg       wakeup_active_stage1;
    
    // Stage 1: Next state computation
    always @(*) begin
        next_state_stage1 = wakeup_state;
        dp_drive_stage1 = dp_drive;
        dm_drive_stage1 = dm_drive;
        wakeup_active_stage1 = wakeup_active;
        
        case (wakeup_state)
            IDLE: begin
                if (trigger_wakeup) begin
                    next_state_stage1 = RESUME_K;
                    dp_drive_stage1 = 1'b0;
                    dm_drive_stage1 = 1'b1;
                    wakeup_active_stage1 = 1'b1;
                end else begin
                    dp_drive_stage1 = 1'b0;
                    dm_drive_stage1 = 1'b0;
                    wakeup_active_stage1 = 1'b0;
                end
            end
            
            RESUME_K: begin
                if (k_state_done) begin
                    next_state_stage1 = RESUME_DONE;
                    dp_drive_stage1 = 1'b0;
                    dm_drive_stage1 = 1'b0;
                end
            end
            
            RESUME_DONE: begin
                wakeup_active_stage1 = 1'b0;
                if (!suspend_state)
                    next_state_stage1 = IDLE;
            end
            
            default: next_state_stage1 = IDLE;
        endcase
    end
    
    // Stage 2: State update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup_state <= IDLE;
            dp_drive <= 1'b0;
            dm_drive <= 1'b0;
            wakeup_active <= 1'b0;
        end else if (stage_valid) begin
            wakeup_state <= next_state_stage1;
            dp_drive <= dp_drive_stage1;
            dm_drive <= dm_drive_stage1;
            wakeup_active <= wakeup_active_stage1;
        end
    end

endmodule