//SystemVerilog
// Top-level module: Hierarchical Reset Detector with Enable using Valid-Ready Handshake
module ResetDetectorWithEnable_ValidReady (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable_valid,
    input  wire        enable,
    output wire        enable_ready,

    output wire        reset_detected_valid,
    input  wire        reset_detected_ready,
    output wire        reset_detected
);

    // Internal signals for valid-ready handshake
    wire               rst_sync_valid;
    wire               rst_sync_ready;
    wire               rst_sync_data;

    wire               reset_status_valid;
    wire               reset_status_ready;
    wire               reset_status_data;

    // Submodule: ResetSynchronizer with valid-ready handshake
    ResetSynchronizer_ValidReady u_reset_synchronizer (
        .clk              (clk),
        .rst_n            (rst_n),
        .rst_sync_valid   (rst_sync_valid),
        .rst_sync_ready   (rst_sync_ready),
        .rst_sync         (rst_sync_data)
    );

    // Submodule: ResetStatusController with valid-ready handshake
    ResetStatusController_ValidReady u_reset_status_controller (
        .clk                   (clk),
        .rst_sync_valid        (rst_sync_valid),
        .rst_sync_ready        (rst_sync_ready),
        .rst_sync              (rst_sync_data),
        .enable_valid          (enable_valid),
        .enable_ready          (enable_ready),
        .enable                (enable),
        .reset_detected_valid  (reset_status_valid),
        .reset_detected_ready  (reset_status_ready),
        .reset_detected        (reset_status_data)
    );

    // Output interface mapping
    assign reset_detected_valid = reset_status_valid;
    assign reset_status_ready   = reset_detected_ready;
    assign reset_detected       = reset_status_data;

endmodule

//------------------------------------------------------------------------------
// Submodule: ResetSynchronizer with Valid-Ready Handshake
// Function: Synchronizes the asynchronous active-low reset signal to the clock
//           domain to avoid metastability issues.
//           Uses valid-ready handshake for data output.
//------------------------------------------------------------------------------
module ResetSynchronizer_ValidReady (
    input  wire clk,
    input  wire rst_n,
    output reg  rst_sync_valid,
    input  wire rst_sync_ready,
    output reg  rst_sync
);
    reg rst_meta;
    reg rst_sync_r;
    reg rst_sync_next;
    reg handshake_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_meta       <= 1'b0;
            rst_sync_r     <= 1'b0;
            rst_sync_valid <= 1'b0;
            handshake_done <= 1'b0;
            rst_sync       <= 1'b0;
        end else begin
            rst_meta   <= 1'b1;
            rst_sync_r <= rst_meta;

            // Valid-Ready handshake for output
            if (!handshake_done) begin
                rst_sync       <= rst_sync_r;
                rst_sync_valid <= 1'b1;
                if (rst_sync_ready) begin
                    handshake_done <= 1'b1;
                    rst_sync_valid <= 1'b0;
                end
            end else begin
                rst_sync_valid <= 1'b0;
            end
        end
    end

endmodule

//------------------------------------------------------------------------------
// Submodule: ResetStatusController with Valid-Ready Handshake
// Function: Generates the reset_detected signal. Sets it high on reset and
//           clears it on enable.
//           Uses valid-ready handshake for both input and output.
//------------------------------------------------------------------------------
module ResetStatusController_ValidReady (
    input  wire clk,
    input  wire rst_sync_valid,
    output wire rst_sync_ready,
    input  wire rst_sync,

    input  wire enable_valid,
    output wire enable_ready,
    input  wire enable,

    output reg  reset_detected_valid,
    input  wire reset_detected_ready,
    output reg  reset_detected
);

    typedef enum logic [1:0] {IDLE, WAIT_ENABLE, OUTPUT} state_t;
    state_t state, next_state;

    reg reset_flag;

    // Input handshake logic
    assign rst_sync_ready = (state == IDLE);
    assign enable_ready   = (state == WAIT_ENABLE);

    always @(posedge clk or negedge rst_sync) begin
        if (!rst_sync) begin
            state               <= IDLE;
            reset_flag          <= 1'b1;
            reset_detected      <= 1'b1;
            reset_detected_valid<= 1'b0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    if (rst_sync_valid && rst_sync_ready) begin
                        reset_flag     <= 1'b1;
                        reset_detected <= 1'b1;
                        reset_detected_valid <= 1'b0;
                    end
                end
                WAIT_ENABLE: begin
                    if (enable_valid && enable_ready && enable) begin
                        reset_flag     <= 1'b0;
                        reset_detected <= 1'b0;
                    end
                end
                OUTPUT: begin
                    if (!reset_flag) begin
                        reset_detected_valid <= 1'b1;
                        if (reset_detected_ready) begin
                            reset_detected_valid <= 1'b0;
                        end
                    end else begin
                        reset_detected_valid <= 1'b1;
                        if (reset_detected_ready) begin
                            reset_detected_valid <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (rst_sync_valid && rst_sync_ready)
                    next_state = WAIT_ENABLE;
            end
            WAIT_ENABLE: begin
                if (enable_valid && enable_ready && enable)
                    next_state = OUTPUT;
            end
            OUTPUT: begin
                if (reset_detected_valid && reset_detected_ready)
                    next_state = IDLE;
            end
        endcase
    end

endmodule