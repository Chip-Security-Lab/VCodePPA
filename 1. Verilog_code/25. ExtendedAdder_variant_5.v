module Adder_3 (
    input aclk,
    input aresetn, // Active low reset

    // AXI-Stream Input Interface
    input s_axis_tvalid,
    output s_axis_tready,
    input [7:0] s_axis_tdata, // Input data: A[7:4], B[3:0]

    // AXI-Stream Output Interface
    output m_axis_tvalid,
    input m_axis_tready,
    output [4:0] m_axis_tdata // Output data: Sum[4:0]
);

    // Internal signals for A and B derived from s_axis_tdata
    wire [3:0] A_in;
    wire [3:0] B_in;

    // Combinational sum calculation
    wire [4:0] sum_comb;

    // Registered output data and valid flag
    reg [4:0] sum_reg;
    reg m_axis_tvalid_reg;

    // Assign A and B from the input TDATA
    // Assuming A occupies the upper 4 bits and B the lower 4 bits of s_axis_tdata
    assign A_in = s_axis_tdata[7:4];
    assign B_in = s_axis_tdata[3:0];

    // Perform the addition combinatorially based on the current input data
    assign sum_comb = {1'b0, A_in} + {1'b0, B_in};

    // s_axis_tready signal generation for input handshake
    // Ready to accept new input if the output buffer is empty or the downstream is ready to accept output
    assign s_axis_tready = ~m_axis_tvalid_reg | m_axis_tready;

    // Sequential logic for pipeline stage and output handshake
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset state
            sum_reg <= 5'b0;
            m_axis_tvalid_reg <= 1'b0;
        end else begin
            // Handle output handshake: clear valid flag when downstream consumes data
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 1'b0;
                // Data in sum_reg is held until new data is loaded
            end

            // Handle input handshake: load new data and set valid flag
            // This happens when input is valid AND the module is ready to accept it
            // s_axis_tready ensures the output buffer is ready for the result
            if (s_axis_tvalid && s_axis_tready) begin
                // Register the result of the combinational addition
                sum_reg <= sum_comb;
                // Mark the output data as valid
                m_axis_tvalid_reg <= 1'b1;
            end
        end
    end

    // Assign output ports from the registered values
    assign m_axis_tdata = sum_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

endmodule