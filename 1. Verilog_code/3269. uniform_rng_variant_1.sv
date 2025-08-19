//SystemVerilog
module uniform_rng_axi_stream (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    output reg [15:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    reg [31:0] x_reg, y_reg, z_reg, w_reg;
    reg [31:0] x_xor1, x_xor2, x_xor3;
    reg        gen_enable;
    reg        clr_valid;

    assign s_axis_tready = 1'b1;
    assign m_axis_tlast  = 1'b0;

    always @(*) begin
        gen_enable = 1'b0;
        clr_valid  = 1'b0;

        if (s_axis_tvalid && s_axis_tready) begin
            if (!m_axis_tvalid) begin
                gen_enable = 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                gen_enable = 1'b1;
            end
        end

        if (m_axis_tvalid && m_axis_tready && !gen_enable) begin
            clr_valid = 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg         <= 32'h12345678;
            y_reg         <= 32'h9ABCDEF0;
            z_reg         <= 32'h13579BDF;
            w_reg         <= 32'h2468ACE0;
            m_axis_tdata  <= 16'h0;
            m_axis_tvalid <= 1'b0;
        end else begin
            if (gen_enable) begin
                x_xor1 <= x_reg ^ (x_reg << 11);
                x_xor2 <= x_xor1 ^ (x_xor1 >> 8);
                x_xor3 <= x_xor2 ^ (y_reg ^ (y_reg >> 19));
                x_reg  <= x_xor3;
                y_reg  <= z_reg;
                z_reg  <= w_reg;
                w_reg  <= x_reg;
                m_axis_tdata  <= w_reg[15:0];
                m_axis_tvalid <= 1'b1;
            end else if (clr_valid) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule