//SystemVerilog
module CrossDomainFSM_AXI (
    // Clock and reset
    input clk_a, clk_b,
    input rst_n,
    
    // AXI-Stream input interface (in clk_a domain)
    input        s_axis_tvalid,  // Replaces req_a
    output       s_axis_tready,  // Handshake signal for input
    
    // AXI-Stream output interface (in clk_b domain)
    output       m_axis_tvalid,  // Handshake signal for output
    input        m_axis_tready,  // Handshake acknowledgment
    output       m_axis_tlast    // Last signal (optional, used for transaction marking)
);
    // Clock domain A signals
    reg req_a_sync;
    reg [1:0] sync_chain_a2b;
    reg s_axis_tready_reg;
    
    // Clock domain B signals
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [1:0] sync_chain_b2a;
    
    // AXI-Stream interface assignments
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    
    // Request synchronizer (clk_a to clk_b)
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) sync_chain_a2b <= 2'b00;
        else sync_chain_a2b <= {sync_chain_a2b[0], s_axis_tvalid};
    end
    
    // Acknowledgment synchronizer (clk_b to clk_a)
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) sync_chain_b2a <= 2'b00;
        else sync_chain_b2a <= {sync_chain_b2a[0], m_axis_tvalid_reg};
    end
    
    // Input ready logic (clk_a domain)
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready_reg <= 1'b1; // Default to ready
        end else begin
            // Only ready when not already processing a transaction
            s_axis_tready_reg <= !sync_chain_b2a[1];
        end
    end
    
    // State machine in clk_b domain using one-hot encoding for better timing
    localparam [1:0] B_IDLE = 2'b01, B_ACTIVE = 2'b10;
    reg [1:0] state_b;
    
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            state_b <= B_IDLE;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
        end else begin
            case(state_b)
                B_IDLE: begin
                    if (sync_chain_a2b[1]) begin
                        m_axis_tvalid_reg <= 1'b1;
                        m_axis_tlast_reg <= 1'b1; // Indicate single transfer
                        state_b <= B_ACTIVE;
                    end
                end
                
                B_ACTIVE: begin
                    if (m_axis_tready) begin
                        // When downstream accepts the data
                        if (!sync_chain_a2b[1]) begin
                            m_axis_tvalid_reg <= 1'b0;
                            m_axis_tlast_reg <= 1'b0;
                            state_b <= B_IDLE;
                        end
                    end
                end
                
                default: state_b <= B_IDLE;
            endcase
        end
    end
endmodule