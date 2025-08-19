//SystemVerilog
module cascaded_clk_divider_axi_stream(
    input clk_in,
    input rst,
    
    // AXI-Stream Master Interface
    output reg        m_axis_tvalid,
    input            m_axis_tready,
    output reg [3:0] m_axis_tdata,
    output reg       m_axis_tlast,
    
    // AXI-Stream Slave Interface
    input            s_axis_tvalid,
    output reg       s_axis_tready,
    input  [3:0]    s_axis_tdata,
    input           s_axis_tlast
);

    reg [3:0] divider;
    reg [2:0] state;
    reg [2:0] next_state;
    
    // State definitions - one-hot encoding
    localparam IDLE = 3'b001;
    localparam TRANSFER = 3'b010;
    localparam WAIT = 3'b100;
    
    // Optimized clock divider logic with balanced paths
    wire [3:0] divider_next;
    wire [3:0] divider_ff;
    
    // Parallel divider logic
    assign divider_next[0] = ~divider[0];
    assign divider_next[1] = ~divider[1];
    assign divider_next[2] = ~divider[2];
    assign divider_next[3] = ~divider[3];
    
    // Synchronized divider flip-flops
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            divider <= 4'b0000;
        end else begin
            divider[0] <= divider_next[0];
            if (divider[0]) divider[1] <= divider_next[1];
            if (divider[1]) divider[2] <= divider_next[2];
            if (divider[2]) divider[3] <= divider_next[3];
        end
    end
    
    // Optimized AXI-Stream state machine with balanced paths
    wire state_transition;
    wire transfer_condition;
    wire wait_condition;
    
    assign state_transition = s_axis_tvalid & (state == IDLE);
    assign transfer_condition = m_axis_tready & (state == TRANSFER);
    assign wait_condition = m_axis_tready & (state == WAIT);
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 4'b0;
            m_axis_tlast <= 1'b0;
            s_axis_tready <= 1'b0;
        end else begin
            // Parallel state transitions
            case (1'b1)
                state_transition: begin
                    state <= TRANSFER;
                    s_axis_tready <= 1'b1;
                end
                
                transfer_condition: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= divider;
                    m_axis_tlast <= 1'b1;
                    state <= WAIT;
                end
                
                wait_condition: begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule