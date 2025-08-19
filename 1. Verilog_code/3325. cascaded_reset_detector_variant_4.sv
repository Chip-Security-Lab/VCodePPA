//SystemVerilog
module cascaded_reset_detector_axi_stream (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   s_axis_tdata,     // AXI-Stream slave data input (reset_triggers)
    input  wire         s_axis_tvalid,    // AXI-Stream slave valid
    output wire         s_axis_tready,    // AXI-Stream slave ready
    input  wire [3:0]   stage_enables,    // Non-stream input (can also be made AXI-Stream if required)
    output wire [3:0]   m_axis_tdata,     // AXI-Stream master data output (stage_resets)
    output wire         m_axis_tvalid,    // AXI-Stream master valid
    input  wire         m_axis_tready,    // AXI-Stream master ready
    output wire         m_axis_tlast,     // AXI-Stream master last
    output wire         system_reset      // Output as before
);

    // Intermediate wires for combinational logic
    wire [3:0] stage_status_comb;
    wire       system_reset_comb;

    reg  [3:0] stage_status_reg;
    reg        stage_status_valid_reg;
    reg        system_reset_reg;

    // AXI-Stream handshake for input
    assign s_axis_tready = (!stage_status_valid_reg);

    // AXI-Stream handshake for output
    assign m_axis_tvalid = stage_status_valid_reg;
    assign m_axis_tdata  = stage_status_reg;
    assign m_axis_tlast  = 1'b1;
    assign system_reset  = system_reset_reg;

    // Combinational logic moved before registers (forward retiming)
    assign stage_status_comb[0] = s_axis_tdata[0] & stage_enables[0];
    assign stage_status_comb[1] = (s_axis_tdata[1] | stage_status_comb[0]) & stage_enables[1];
    assign stage_status_comb[2] = (s_axis_tdata[2] | stage_status_comb[1]) & stage_enables[2];
    assign stage_status_comb[3] = (s_axis_tdata[3] | stage_status_comb[2]) & stage_enables[3];

    assign system_reset_comb = |stage_status_comb;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_status_reg      <= 4'b0000;
            stage_status_valid_reg<= 1'b0;
            system_reset_reg      <= 1'b0;
        end else begin
            // Accept new input only if output is not valid or has been accepted
            if (s_axis_tvalid && s_axis_tready) begin
                stage_status_reg      <= stage_status_comb;
                system_reset_reg      <= system_reset_comb;
                stage_status_valid_reg<= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                stage_status_valid_reg<= 1'b0;
            end
        end
    end

endmodule