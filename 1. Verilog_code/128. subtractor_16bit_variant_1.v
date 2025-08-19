module subtractor_16bit_axi_stream (
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface
    input wire [15:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface
    output reg [15:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);

    // Internal registers
    reg [15:0] a_reg;
    reg [15:0] b_reg;
    reg [15:0] diff_reg;
    reg [1:0] state;
    reg [1:0] next_state;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam WAIT_B = 2'b01;
    localparam COMPUTE = 2'b10;
    localparam OUTPUT = 2'b11;
    
    // State machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = s_axis_tvalid ? WAIT_B : IDLE;
            WAIT_B: next_state = s_axis_tvalid ? COMPUTE : WAIT_B;
            COMPUTE: next_state = OUTPUT;
            OUTPUT: next_state = m_axis_tready ? IDLE : OUTPUT;
            default: next_state = IDLE;
        endcase
    end
    
    // Data path
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            a_reg <= 16'b0;
            b_reg <= 16'b0;
            diff_reg <= 16'b0;
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 16'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_tready <= 1'b1;
                    m_axis_tvalid <= 1'b0;
                    if (s_axis_tvalid) begin
                        a_reg <= s_axis_tdata;
                    end
                end
                
                WAIT_B: begin
                    s_axis_tready <= 1'b1;
                    if (s_axis_tvalid) begin
                        b_reg <= s_axis_tdata;
                    end
                end
                
                COMPUTE: begin
                    s_axis_tready <= 1'b0;
                    diff_reg <= a_reg - b_reg;
                end
                
                OUTPUT: begin
                    s_axis_tready <= 1'b0;
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= diff_reg;
                    m_axis_tlast <= 1'b1;
                end
                
                default: begin
                    s_axis_tready <= 1'b0;
                    m_axis_tvalid <= 1'b0;
                end
            endcase
        end
    end

endmodule