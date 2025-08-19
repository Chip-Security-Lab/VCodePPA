//SystemVerilog
module rng_lcg_4_axi_stream (
    input               clk,
    input               rst,
    input               s_axis_tvalid,
    output              s_axis_tready,
    output reg  [31:0]  m_axis_tdata,
    output reg          m_axis_tvalid,
    input               m_axis_tready,
    output reg          m_axis_tlast
);
    parameter A = 32'h41C64E6D;
    parameter C = 32'h00003039;

    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        RESET  = 2'b01,
        ENABLE = 2'b10
    } state_t;

    state_t current_state, next_state;
    reg [31:0] rand_val;
    reg init_done;

    assign s_axis_tready = (current_state == IDLE);

    // State Machine for AXI-Stream Handshake and RNG Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= RESET;
            rand_val <= 32'h12345678;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 32'd0;
            m_axis_tlast <= 1'b0;
            init_done <= 1'b0;
        end else begin
            current_state <= next_state;

            case (current_state)
                RESET: begin
                    rand_val <= 32'h12345678;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tdata <= 32'd0;
                    m_axis_tlast <= 1'b0;
                    init_done <= 1'b1;
                end
                ENABLE: begin
                    if (m_axis_tready) begin
                        rand_val <= rand_val * A + C;
                        m_axis_tdata <= rand_val * A + C;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= 1'b0;
                    end else begin
                        m_axis_tvalid <= m_axis_tvalid;
                        m_axis_tdata <= m_axis_tdata;
                        m_axis_tlast <= m_axis_tlast;
                    end
                end
                IDLE: begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tdata <= m_axis_tdata;
                    m_axis_tlast <= 1'b0;
                end
                default: begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tdata <= m_axis_tdata;
                    m_axis_tlast <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        case (current_state)
            RESET: begin
                if (init_done)
                    next_state = IDLE;
                else
                    next_state = RESET;
            end
            IDLE: begin
                if (s_axis_tvalid && s_axis_tready)
                    next_state = ENABLE;
                else
                    next_state = IDLE;
            end
            ENABLE: begin
                if (m_axis_tvalid && m_axis_tready)
                    next_state = IDLE;
                else
                    next_state = ENABLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule