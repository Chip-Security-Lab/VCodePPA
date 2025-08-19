//SystemVerilog
module security_violation_axi_stream(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   access_violations,   // Memory protection violations
    input  wire [3:0]   crypto_alerts,       // Cryptographic check failures
    input  wire [3:0]   tamper_detections,   // Physical tamper detections
    input  wire [3:0]   violation_mask,      // Enable specific violation types
    output wire [7:0]   m_axis_tdata,        // {violation_type[2:0], secure_reset, 4'b0000}
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    output reg          m_axis_tlast
);

    reg security_violation_flag;
    reg [2:0] violation_type_reg;
    reg secure_reset_flag;
    reg [1:0] stream_state, next_stream_state;

    localparam IDLE      = 2'd0;
    localparam DATA_SEND = 2'd1;

    wire [3:0] masked_violations = (
        (access_violations   & {4{violation_mask[0]}}) |
        (crypto_alerts       & {4{violation_mask[1]}}) |
        (tamper_detections   & {4{violation_mask[2]}})
    );

    // Violation type and flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            security_violation_flag <= 1'b0;
            violation_type_reg      <= 3'b000;
            secure_reset_flag       <= 1'b0;
        end else begin
            security_violation_flag <= |masked_violations;

            // Determine violation type (priority encoded)
            if (|tamper_detections)
                violation_type_reg <= 3'b001;
            else if (|crypto_alerts)
                violation_type_reg <= 3'b010;
            else if (|access_violations)
                violation_type_reg <= 3'b011;
            else
                violation_type_reg <= 3'b000;

            secure_reset_flag <= security_violation_flag;
        end
    end

    // AXI-Stream state machine for TVALID/TREADY handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stream_state <= IDLE;
        end else begin
            stream_state <= next_stream_state;
        end
    end

    always @(*) begin
        next_stream_state = stream_state;
        case (stream_state)
            IDLE: begin
                if (security_violation_flag)
                    next_stream_state = DATA_SEND;
            end
            DATA_SEND: begin
                if (m_axis_tvalid && m_axis_tready)
                    next_stream_state = IDLE;
            end
        endcase
    end

    // AXI-Stream handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            case (stream_state)
                IDLE: begin
                    if (security_violation_flag) begin
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast  <= 1'b1;
                    end else begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast  <= 1'b0;
                    end
                end
                DATA_SEND: begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast  <= 1'b0;
                    end
                end
                default: begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast  <= 1'b0;
                end
            endcase
        end
    end

    // AXI-Stream data output
    assign m_axis_tdata = {violation_type_reg, secure_reset_flag, 4'b0000};

endmodule