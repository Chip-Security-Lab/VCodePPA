module mwc_random_gen (
    input clock,
    input reset,
    output [31:0] random_data
);
    reg [31:0] m_w, m_z;
    
    always @(posedge clock) begin
        if (reset) begin
            m_w <= 32'h12345678;
            m_z <= 32'h87654321;
        end else begin
            m_z <= 36969 * (m_z & 16'hFFFF) + (m_z >> 16);
            m_w <= 18000 * (m_w & 16'hFFFF) + (m_w >> 16);
        end
    end
    
    assign random_data = (m_z << 16) + m_w;
endmodule
