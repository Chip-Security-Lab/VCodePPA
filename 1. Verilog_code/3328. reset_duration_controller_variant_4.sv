//SystemVerilog
// Verilog
// Top-level module: AXI-Stream based reset duration controller

module reset_duration_controller_axi_stream #(
    parameter MIN_DURATION = 16'd100,
    parameter MAX_DURATION = 16'd10000
)(
    input  wire         clk,
    input  wire         rst_n,

    // AXI-Stream Slave (Input) Interface
    input  wire [15:0]  s_axis_tdata,       // Requested duration
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,       // Optional: marks trigger event

    // AXI-Stream Master (Output) Interface
    output wire [15:0]  m_axis_tdata,       // Output: reset_active status
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast        // Optional: marks end of reset
);

    // Internal signals
    wire [15:0] actual_duration;
    wire        duration_update;
    wire        counter_reset;
    wire        counter_enable;
    wire [15:0] counter_value;
    wire        reset_end;

    // Internal handshake and state signals
    reg  [15:0] requested_duration_reg;
    reg         trigger_reg;
    reg         s_axis_tready_reg;
    reg         m_axis_tvalid_reg;
    reg  [15:0] m_axis_tdata_reg;
    reg         m_axis_tlast_reg;

    wire        reset_active;
    reg         reset_active_d;

    // AXI-Stream slave ready: accept new request if not in reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready_reg      <= 1'b1;
            requested_duration_reg <= 16'd0;
            trigger_reg            <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready_reg) begin
                requested_duration_reg <= s_axis_tdata;
                trigger_reg            <= s_axis_tlast; // Use tlast as trigger
                s_axis_tready_reg      <= 1'b0;
            end else if (!reset_active) begin
                s_axis_tready_reg      <= 1'b1;
                trigger_reg            <= 1'b0;
            end
        end
    end

    assign s_axis_tready = s_axis_tready_reg;

    // Duration Constraint Module (AXI-Stream adaptation)
    duration_constrainer #(
        .MIN_DURATION(MIN_DURATION),
        .MAX_DURATION(MAX_DURATION)
    ) u_duration_constrainer (
        .clk                (clk),
        .requested_duration (requested_duration_reg),
        .actual_duration    (actual_duration),
        .update             (duration_update)
    );

    // Counter Module
    reset_counter u_reset_counter (
        .clk         (clk),
        .rst         (counter_reset),
        .en          (counter_enable),
        .count_value (counter_value)
    );

    // Reset State Control Module
    reset_state_ctrl u_reset_state_ctrl (
        .clk             (clk),
        .rst_n           (rst_n),
        .trigger         (trigger_reg),
        .counter_value   (counter_value),
        .actual_duration (actual_duration),
        .reset_active    (reset_active),
        .counter_reset   (counter_reset),
        .counter_enable  (counter_enable),
        .duration_update (duration_update),
        .reset_end       (reset_end)
    );

    // AXI-Stream Master (Output) handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tdata_reg  <= 16'd0;
            m_axis_tlast_reg  <= 1'b0;
            reset_active_d    <= 1'b0;
        end else begin
            reset_active_d <= reset_active;

            // Output valid when reset ends
            if (reset_end) begin
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tdata_reg  <= 16'd0; // Reset is inactive
                m_axis_tlast_reg  <= 1'b1;
            end else if (reset_active && !reset_active_d) begin
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tdata_reg  <= 16'd1; // Reset is active
                m_axis_tlast_reg  <= 1'b0;
            end else if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 1'b0;
                m_axis_tlast_reg  <= 1'b0;
            end
        end
    end

    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast  = m_axis_tlast_reg;

endmodule

//-----------------------------------------------------------------------------
// Duration Constrainer
//-----------------------------------------------------------------------------
module duration_constrainer #(
    parameter MIN_DURATION = 16'd100,
    parameter MAX_DURATION = 16'd10000
)(
    input  wire        clk,
    input  wire [15:0] requested_duration,
    output reg  [15:0] actual_duration,
    output wire        update
);
    assign update = 1'b1; // Always update for this design

    always @(posedge clk) begin
        if (requested_duration < MIN_DURATION)
            actual_duration <= MIN_DURATION;
        else if (requested_duration > MAX_DURATION)
            actual_duration <= MAX_DURATION;
        else
            actual_duration <= requested_duration;
    end
endmodule

//-----------------------------------------------------------------------------
// Reset Counter
//-----------------------------------------------------------------------------
module reset_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    output reg  [15:0] count_value
);
    always @(posedge clk) begin
        if (rst)
            count_value <= 16'd0;
        else if (en)
            count_value <= count_value + 16'd1;
    end
endmodule

//-----------------------------------------------------------------------------
// Reset State Control
//-----------------------------------------------------------------------------
module reset_state_ctrl (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger,
    input  wire [15:0] counter_value,
    input  wire [15:0] actual_duration,
    output reg         reset_active,
    output reg         counter_reset,
    output reg         counter_enable,
    output wire        duration_update,
    output reg         reset_end
);
    assign duration_update = 1'b1; // Always update duration

    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        ACTIVE = 2'b01,
        DONE   = 2'b10
    } state_t;

    state_t state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            reset_active  <= 1'b0;
            counter_reset <= 1'b1;
            counter_enable<= 1'b0;
            reset_end     <= 1'b0;
        end else begin
            state         <= next_state;
        end
    end

    always @(*) begin
        counter_reset  = 1'b0;
        counter_enable = 1'b0;
        reset_end      = 1'b0;
        case (state)
            IDLE: begin
                if (trigger) begin
                    counter_reset  = 1'b1;
                end
            end
            ACTIVE: begin
                counter_enable = 1'b1;
                if (counter_value >= actual_duration - 1) begin
                    counter_reset = 1'b1;
                    reset_end     = 1'b1;
                end
            end
            DONE: begin
                // Wait for output handshake
            end
        endcase
    end

    always @(*) begin
        next_state    = state;
        case (state)
            IDLE: begin
                reset_active = 1'b0;
                if (trigger)
                    next_state = ACTIVE;
            end
            ACTIVE: begin
                reset_active = 1'b1;
                if (counter_value >= actual_duration - 1)
                    next_state = DONE;
            end
            DONE: begin
                reset_active = 1'b0;
                next_state = IDLE;
            end
        endcase
    end
endmodule