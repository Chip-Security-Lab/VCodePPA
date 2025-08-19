//SystemVerilog
module bbs_rng_axi_stream (
    input  wire        aclk,
    input  wire        aresetn,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    parameter P = 11;
    parameter Q = 23;
    parameter M = P * Q;   // 253

    // Internal signals
    reg  [15:0] rng_state_reg;
    reg         tvalid_reg;
    wire [15:0] rng_state_next;
    wire        tvalid_next;

    reg  [7:0]  rng_output_reg;

    // Combinational logic for next state and tvalid
    assign rng_state_next = (!aresetn)                ? 16'd3 :
                            (m_axis_tready && tvalid_reg) ? (rng_state_reg * rng_state_reg) % M :
                            rng_state_reg;

    assign tvalid_next = (!aresetn) ? 1'b0 : 1'b1;

    // Sequential logic for state and tvalid registers
    always @(posedge aclk) begin
        rng_state_reg <= rng_state_next;
        tvalid_reg    <= tvalid_next;
    end

    // Move output register after rng_state_reg
    always @(posedge aclk) begin
        if (!aresetn)
            rng_output_reg <= 8'd0;
        else if (m_axis_tready && tvalid_reg)
            rng_output_reg <= rng_state_next[7:0];
        else
            rng_output_reg <= rng_output_reg;
    end

    assign m_axis_tdata  = rng_output_reg;
    assign m_axis_tvalid = tvalid_reg;

endmodule