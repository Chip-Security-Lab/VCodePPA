//SystemVerilog
module IVMU_AXIS #(
    parameter integer TDATA_WIDTH = 64 // AXI-Stream data width, must be >= 33
)(
    input wire aclk,         // Clock
    input wire aresetn,      // Asynchronous reset, active low

    // Original inputs (kept as standard inputs)
    input wire [7:0] int_lines,
    input wire [7:0] int_mask,

    // AXI-Stream Output Interface
    output wire m_axis_tvalid,
    output wire [TDATA_WIDTH-1:0] m_axis_tdata,
    input wire m_axis_tready
);

    // Ensure TDATA_WIDTH is sufficient
    generate
        if (TDATA_WIDTH < 33) begin : tdata_width_error
            $error("TDATA_WIDTH must be at least 33 to accommodate vector_out (32) and int_active (1).");
        end
    endgenerate

    // Internal signals for original logic
    reg [31:0] vector_map [0:7]; // Lookup table for vectors
    wire [7:0] masked_ints;     // Interrupts after applying mask
    reg [2:0] active_int;       // Stores index of active interrupt (lowest index wins as per original code)
    integer i;                  // Loop variable

    // Combinational outputs of original logic
    wire [31:0] vector_out_comb; // Combinational vector output
    wire int_active_comb;       // Combinational active status

    // Registered AXI-Stream output signals
    reg m_axis_tvalid_reg;      // Registered TVALID
    reg [TDATA_WIDTH-1:0] m_axis_tdata_reg; // Registered TDATA

    // Constant lookup table initialization
    // In a real synthesis flow, this array access would likely infer a ROM
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_map[i] = 32'h2000_0000 + (i * 4);
        end
    end

    // --- Original Logic (combinational part) ---

    // Apply mask to interrupt lines
    assign masked_ints = int_lines & ~int_mask;

    // Determine if any masked interrupt is active
    assign int_active_comb = |masked_ints;

    // Determine the index of the active interrupt with the lowest index (as per original loop)
    // The loop iterates from 7 down to 0. The last assignment to active_int wins,
    // which corresponds to the lowest index i where masked_ints[i] is true.
    always @(*) begin
        active_int = 0; // Default value if no interrupts are active
        for (i = 7; i >= 0; i = i - 1) begin
            if (masked_ints[i]) begin
                active_int = i[2:0];
            end
        end
    end

    // Lookup the vector based on the active interrupt index
    assign vector_out_comb = vector_map[active_int];

    // --- End Original Logic ---

    // --- AXI-Stream Output Logic ---

    // Register AXI-Stream output signals
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset state
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tdata_reg <= {TDATA_WIDTH{1'b0}}; // Initialize data to zero
        end else begin
            // Data generation logic:
            // New data is ready from original logic when int_active_comb is high.
            // Load new data into output registers when:
            // 1. int_active_comb is high AND
            // 2. The output buffer is empty (!m_axis_tvalid_reg) OR the downstream is ready (m_axis_tready).
            if (int_active_comb) begin
                if (!m_axis_tvalid_reg || m_axis_tready) begin
                    // Load new data: {unused, int_active, vector_out}
                    // int_active_comb is placed at bit 32, vector_out_comb at bits [31:0]
                    m_axis_tdata_reg <= {{TDATA_WIDTH-33{1'b0}}, int_active_comb, vector_out_comb};
                    m_axis_tvalid_reg <= 1'b1; // Data is now valid
                end
                // If int_active_comb is high but (!m_axis_tvalid_reg || m_axis_tready) is false,
                // the registers hold the previous state and TVALID remains high (if it was high).
            end else begin // int_active_comb is low
                // If there was valid data being sent (from a previous high int_active_comb),
                // and the downstream consumes it, deassert TVALID.
                if (m_axis_tvalid_reg && m_axis_tready) begin
                    m_axis_tvalid_reg <= 1'b0; // Data consumed, no new data available
                end
                // If int_active_comb goes low but the previous valid data hasn't been consumed,
                // TVALID remains high until m_axis_tready goes high.
            end
        end
    end

    // Assign registered values to output ports
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tdata = m_axis_tdata_reg;

endmodule