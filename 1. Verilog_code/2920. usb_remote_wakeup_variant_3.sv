//SystemVerilog
`timescale 1ns / 1ps

// Top module that instantiates all sub-modules
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

    // Internal connections between modules
    wire       wakeup_trigger;
    wire       k_interval_done;
    wire [2:0] fsm_state;
    wire       drive_k_state;
    wire       drive_idle_state;

    // Control logic module - determines when to trigger the wakeup process
    usb_wakeup_control_logic u_control_logic (
        .suspend_state        (suspend_state),
        .remote_wakeup_enabled(remote_wakeup_enabled),
        .wakeup_request       (wakeup_request),
        .wakeup_trigger       (wakeup_trigger)
    );

    // State machine module - controls the wakeup sequence
    usb_wakeup_state_machine u_state_machine (
        .clk            (clk),
        .rst_n          (rst_n),
        .wakeup_trigger (wakeup_trigger),
        .suspend_state  (suspend_state),
        .k_interval_done(k_interval_done),
        .wakeup_state   (fsm_state),
        .wakeup_active  (wakeup_active),
        .drive_k_state  (drive_k_state),
        .drive_idle_state(drive_idle_state)
    );

    // Timer module - ensures K state is driven for the correct duration
    usb_wakeup_timer u_timer (
        .clk            (clk),
        .rst_n          (rst_n),
        .drive_k_state  (drive_k_state),
        .k_interval_done(k_interval_done)
    );

    // Line driver module - controls the USB D+/D- lines
    usb_wakeup_line_driver u_line_driver (
        .clk             (clk),
        .rst_n           (rst_n),
        .drive_k_state   (drive_k_state),
        .drive_idle_state(drive_idle_state),
        .dp_drive        (dp_drive),
        .dm_drive        (dm_drive)
    );

    // Expose FSM state to the output
    assign wakeup_state = fsm_state;

endmodule

// Control Logic Module
module usb_wakeup_control_logic (
    input  wire suspend_state,
    input  wire remote_wakeup_enabled,
    input  wire wakeup_request,
    output wire wakeup_trigger
);

    // Generate wakeup trigger when all conditions are met
    assign wakeup_trigger = suspend_state && remote_wakeup_enabled && wakeup_request;

endmodule

// State Machine Module
module usb_wakeup_state_machine (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       wakeup_trigger,
    input  wire       suspend_state,
    input  wire       k_interval_done,
    output reg  [2:0] wakeup_state,
    output reg        wakeup_active,
    output reg        drive_k_state,
    output reg        drive_idle_state
);

    // Wakeup state machine states
    localparam IDLE        = 3'd0;
    localparam RESUME_K    = 3'd1;
    localparam RESUME_DONE = 3'd2;

    // Next state signals
    reg [2:0] next_wakeup_state;
    reg       next_wakeup_active;
    reg       next_drive_k_state;
    reg       next_drive_idle_state;

    // State transition and output logic
    always @(*) begin
        // Default: maintain current values
        next_wakeup_state     = wakeup_state;
        next_wakeup_active    = wakeup_active;
        next_drive_k_state    = drive_k_state;
        next_drive_idle_state = drive_idle_state;

        case (wakeup_state)
            IDLE: begin
                if (wakeup_trigger) begin
                    next_wakeup_state     = RESUME_K;
                    next_wakeup_active    = 1'b1;
                    next_drive_k_state    = 1'b1;
                    next_drive_idle_state = 1'b0;
                end else begin
                    next_drive_k_state    = 1'b0;
                    next_drive_idle_state = 1'b1;
                    next_wakeup_active    = 1'b0;
                end
            end
            
            RESUME_K: begin
                if (k_interval_done) begin
                    next_wakeup_state     = RESUME_DONE;
                    next_drive_k_state    = 1'b0;
                    next_drive_idle_state = 1'b1;
                end
            end
            
            RESUME_DONE: begin
                next_wakeup_active = 1'b0;
                if (!suspend_state)
                    next_wakeup_state = IDLE;
            end
            
            default: begin
                next_wakeup_state     = IDLE;
                next_drive_k_state    = 1'b0;
                next_drive_idle_state = 1'b1;
                next_wakeup_active    = 1'b0;
            end
        endcase
    end

    // State registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup_state     <= IDLE;
            wakeup_active    <= 1'b0;
            drive_k_state    <= 1'b0;
            drive_idle_state <= 1'b1;
        end else begin
            wakeup_state     <= next_wakeup_state;
            wakeup_active    <= next_wakeup_active;
            drive_k_state    <= next_drive_k_state;
            drive_idle_state <= next_drive_idle_state;
        end
    end

endmodule

// Timer Module
module usb_wakeup_timer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       drive_k_state,
    output wire       k_interval_done
);

    // Constants for timing
    localparam K_DURATION_CYCLES = 16'd50000; // ~1ms at 48MHz

    // Counter registers
    reg [15:0] k_counter;
    reg [15:0] next_k_counter;

    // Counter logic
    always @(*) begin
        if (drive_k_state)
            next_k_counter = k_counter + 16'd1;
        else
            next_k_counter = 16'd0;
    end

    // Register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_counter <= 16'd0;
        end else begin
            k_counter <= next_k_counter;
        end
    end

    // Completion signal
    assign k_interval_done = (k_counter >= K_DURATION_CYCLES);

endmodule

// Line Driver Module
module usb_wakeup_line_driver (
    input  wire clk,
    input  wire rst_n,
    input  wire drive_k_state,
    input  wire drive_idle_state,
    output reg  dp_drive,
    output reg  dm_drive
);

    // Next state signals
    reg next_dp_drive;
    reg next_dm_drive;

    // K-state and idle state logic
    always @(*) begin
        if (drive_k_state) begin
            // Drive K state (dp=0, dm=1)
            next_dp_drive = 1'b0;
            next_dm_drive = 1'b1;
        end else if (drive_idle_state) begin
            // Idle state (don't drive lines)
            next_dp_drive = 1'b0;
            next_dm_drive = 1'b0;
        end else begin
            // Maintain current state
            next_dp_drive = dp_drive;
            next_dm_drive = dm_drive;
        end
    end

    // Register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_drive <= 1'b0;
            dm_drive <= 1'b0;
        end else begin
            dp_drive <= next_dp_drive;
            dm_drive <= next_dm_drive;
        end
    end

endmodule