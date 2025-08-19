//SystemVerilog
module mwc_random_gen (
    input  wire        clock,
    input  wire        reset,
    output wire [31:0] random_data
);

    reg  [31:0] m_w_reg, m_z_reg;
    wire [31:0] m_z_shifted_wire, m_w_shifted_wire;
    reg  [31:0] m_z_shifted_buf, m_w_shifted_buf;
    reg  [31:0] m_z_next, m_w_next;
    reg  [31:0] m_z_left_shift_buf, m_w_buf;
    wire [31:0] random_data_wire;

    // Barrel shifter for m_z >> 16
    function [31:0] barrel_shifter_right_16;
        input [31:0] in_data;
        begin
            barrel_shifter_right_16 = {16'b0, in_data[31:16]};
        end
    endfunction

    // Barrel shifter for m_w >> 16
    function [31:0] barrel_shifter_right_16_w;
        input [31:0] in_data;
        begin
            barrel_shifter_right_16_w = {16'b0, in_data[31:16]};
        end
    endfunction

    // Barrel shifter for m_z << 16
    function [31:0] barrel_shifter_left_16;
        input [31:0] in_data;
        begin
            barrel_shifter_left_16 = {in_data[15:0], 16'b0};
        end
    endfunction

    // Stage 1: combinational calculation of shifters
    assign m_z_shifted_wire = barrel_shifter_right_16(m_z_reg);
    assign m_w_shifted_wire = barrel_shifter_right_16_w(m_w_reg);

    // Stage 2: Buffering the high fanout signals (flattened control)
    always @(posedge clock) begin
        if (reset) begin
            m_z_shifted_buf <= 32'h00000000;
            m_w_shifted_buf <= 32'h00000000;
        end else if (!reset) begin
            m_z_shifted_buf <= m_z_shifted_wire;
            m_w_shifted_buf <= m_w_shifted_wire;
        end
    end

    // Stage 3: Next state computation using buffered signals
    always @(*) begin
        m_z_next = 36969 * (m_z_reg & 32'h0000FFFF) + m_z_shifted_buf;
        m_w_next = 18000 * (m_w_reg & 32'h0000FFFF) + m_w_shifted_buf;
    end

    // Stage 4: Registers for m_z, m_w (flattened control)
    always @(posedge clock) begin
        if (reset) begin
            m_w_reg <= 32'h12345678;
            m_z_reg <= 32'h87654321;
        end else if (!reset) begin
            m_z_reg <= m_z_next;
            m_w_reg <= m_w_next;
        end
    end

    // Stage 5: Buffering for barrel_shifter_left_16 and m_w_reg for fanout balance (flattened control)
    always @(posedge clock) begin
        if (reset) begin
            m_z_left_shift_buf <= 32'h00000000;
            m_w_buf            <= 32'h00000000;
        end else if (!reset) begin
            m_z_left_shift_buf <= barrel_shifter_left_16(m_z_reg);
            m_w_buf            <= m_w_reg;
        end
    end

    // Stage 6: Output computation
    assign random_data_wire = m_z_left_shift_buf + m_w_buf;
    assign random_data = random_data_wire;

endmodule