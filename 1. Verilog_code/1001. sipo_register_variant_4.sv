//SystemVerilog
module sipo_register_axi_stream (
    input wire clk,
    input wire rst,
    input wire serial_in,
    input wire s_axis_tready,
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast
);

    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg loading;

    // Functional block: Reset and loading state management
    always @(posedge clk) begin
        if (rst) begin
            loading <= 1'b1;
        end else if (loading && (bit_count == 3'd7)) begin
            loading <= 1'b0;
        end else if (~loading && m_axis_tvalid && s_axis_tready) begin
            loading <= 1'b1;
        end
    end

    // Functional block: Shift register operation
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 8'b0;
        end else if (loading) begin
            shift_reg <= {shift_reg[6:0], serial_in};
        end else if (~loading && m_axis_tvalid && s_axis_tready) begin
            shift_reg <= 8'b0;
        end
    end

    // Functional block: Bit counter management
    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 3'b0;
        end else if (loading && (bit_count != 3'd7)) begin
            bit_count <= bit_count + 1'b1;
        end else if (~loading && m_axis_tvalid && s_axis_tready) begin
            bit_count <= 3'b0;
        end
    end

    // Functional block: Output data valid and last signal generation
    always @(posedge clk) begin
        if (rst) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (loading && (bit_count == 3'd7)) begin
            m_axis_tvalid <= 1'b1;
            m_axis_tlast  <= 1'b1;
        end else if (~loading && m_axis_tvalid && s_axis_tready) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end
    end

    // Functional block: Output data assignment
    always @(posedge clk) begin
        if (rst) begin
            m_axis_tdata <= 8'b0;
        end else if (loading && (bit_count == 3'd7)) begin
            m_axis_tdata <= {shift_reg[6:0], serial_in};
        end else if (~loading && m_axis_tvalid && s_axis_tready) begin
            m_axis_tdata <= 8'b0;
        end
    end

endmodule