//SystemVerilog
// AXI-Stream interface version of cascaded_reset_detector
module cascaded_reset_detector_axi_stream (
    input  wire        aclk,
    input  wire        aresetn,
    // AXI-Stream slave interface for input triggers
    input  wire [3:0]  s_axis_tdata,       // reset_triggers
    input  wire [3:0]  s_axis_tuser,       // stage_enables
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // AXI-Stream master interface for output resets
    output wire [3:0]  m_axis_tdata,       // stage_resets
    output wire        m_axis_tuser,       // system_reset
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);

    // Internal signals
    reg  [3:0] reset_triggers_reg;
    reg  [3:0] stage_enables_reg;
    reg        valid_reg;
    reg        ready_reg;

    // AXI-Stream handshake for slave
    assign s_axis_tready = !valid_reg || (m_axis_tready && valid_reg);

    // Data capture logic for slave interface
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reset_triggers_reg <= 4'b0;
            stage_enables_reg  <= 4'b0;
            valid_reg          <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            reset_triggers_reg <= s_axis_tdata;
            stage_enables_reg  <= s_axis_tuser;
            valid_reg          <= 1'b1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            valid_reg          <= 1'b0;
        end
    end

    // Internal signals for inter-stage connections
    wire [3:0] stage_status;

    // Stage 1: Direct reset detector
    stage_reset_unit #(
        .STAGE_INDEX(0)
    ) u_stage_reset_unit_0 (
        .clk                (aclk),
        .rst_n              (aresetn),
        .reset_trigger      (reset_triggers_reg[0]),
        .stage_enable       (stage_enables_reg[0]),
        .prev_stage_status  (1'b0),
        .stage_status       (stage_status[0])
    );

    // Stage 2: Depends on stage 1
    stage_reset_unit #(
        .STAGE_INDEX(1)
    ) u_stage_reset_unit_1 (
        .clk                (aclk),
        .rst_n              (aresetn),
        .reset_trigger      (reset_triggers_reg[1]),
        .stage_enable       (stage_enables_reg[1]),
        .prev_stage_status  (stage_status[0]),
        .stage_status       (stage_status[1])
    );

    // Stage 3: Depends on stage 2
    stage_reset_unit #(
        .STAGE_INDEX(2)
    ) u_stage_reset_unit_2 (
        .clk                (aclk),
        .rst_n              (aresetn),
        .reset_trigger      (reset_triggers_reg[2]),
        .stage_enable       (stage_enables_reg[2]),
        .prev_stage_status  (stage_status[1]),
        .stage_status       (stage_status[2])
    );

    // Stage 4: Depends on stage 3
    stage_reset_unit #(
        .STAGE_INDEX(3)
    ) u_stage_reset_unit_3 (
        .clk                (aclk),
        .rst_n              (aresetn),
        .reset_trigger      (reset_triggers_reg[3]),
        .stage_enable       (stage_enables_reg[3]),
        .prev_stage_status  (stage_status[2]),
        .stage_status       (stage_status[3])
    );

    // System reset generator
    wire system_reset_signal;
    system_reset_unit u_system_reset_unit (
        .clk           (aclk),
        .rst_n         (aresetn),
        .stage_status  (stage_status),
        .system_reset  (system_reset_signal)
    );

    // Output AXI-Stream signals
    reg [3:0]  m_axis_tdata_reg;
    reg        m_axis_tuser_reg;
    reg        m_axis_tvalid_reg;

    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tuser  = m_axis_tuser_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tdata_reg  <= 4'b0;
            m_axis_tuser_reg  <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
        end else begin
            if ((valid_reg && !m_axis_tvalid_reg) || (valid_reg && m_axis_tvalid_reg && m_axis_tready)) begin
                m_axis_tdata_reg  <= stage_status;
                m_axis_tuser_reg  <= system_reset_signal;
                m_axis_tvalid_reg <= 1'b1;
            end else if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 1'b0;
            end
        end
    end

endmodule

// ===========================================================================
// Stage Reset Unit: Generates the reset signal for each stage
// Parameters:
//   STAGE_INDEX - Index of the stage (for reuse and clarity)
// Inputs:
//   clk, rst_n - Clock and active-low reset
//   reset_trigger - External trigger for this stage
//   stage_enable - Enable signal for this stage
//   prev_stage_status - The reset status of the previous stage (or 0 for stage 0)
// Outputs:
//   stage_status - The reset status of this stage
// ===========================================================================
module stage_reset_unit #(
    parameter STAGE_INDEX = 0
)(
    input  wire clk,
    input  wire rst_n,
    input  wire reset_trigger,
    input  wire stage_enable,
    input  wire prev_stage_status,
    output reg  stage_status
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_status <= 1'b0;
        end else begin
            if (STAGE_INDEX == 0) begin
                stage_status <= reset_trigger & stage_enable;
            end else begin
                stage_status <= (reset_trigger | prev_stage_status) & stage_enable;
            end
        end
    end
endmodule

// ===========================================================================
// System Reset Unit: Generates the system reset signal when any stage is active
// Inputs:
//   clk, rst_n - Clock and active-low reset
//   stage_status - Vector of all stage statuses
// Outputs:
//   system_reset - System reset output
// ===========================================================================
module system_reset_unit(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] stage_status,
    output reg        system_reset
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            system_reset <= 1'b0;
        end else begin
            system_reset <= |stage_status;
        end
    end
endmodule