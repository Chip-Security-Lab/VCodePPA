//SystemVerilog
module CascadedITRC_AXI_Stream (
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface for IRQ Inputs
    input wire s_axis_irq_tvalid,
    output reg s_axis_irq_tready,
    input wire [7:0] s_axis_irq_tdata,  // {top_level_irq[1:0], low_level_irq0[3:0], low_level_irq1[3:0]}
    
    // AXI-Stream Master Interface for IRQ Outputs
    output reg m_axis_irq_tvalid,
    input wire m_axis_irq_tready,
    output reg [3:0] m_axis_irq_tdata,  // {master_irq, irq_vector[2:0]}
    output reg m_axis_irq_tlast
);

    wire [1:0] top_level_irq;
    wire [3:0] low_level_irq0;
    wire [3:0] low_level_irq1;
    wire [1:0] low_level_active;
    reg [2:0] low_priority [0:1];
    reg master_irq;
    reg [2:0] irq_vector;
    
    // Extract IRQ signals from AXI-Stream data
    assign top_level_irq = s_axis_irq_tdata[7:6];
    assign low_level_irq0 = s_axis_irq_tdata[5:2];
    assign low_level_irq1 = s_axis_irq_tdata[1:0];
    
    assign low_level_active[0] = |low_level_irq0;
    assign low_level_active[1] = |low_level_irq1;
    
    // AXI-Stream handshake state machine
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam SEND = 2'b10;

    // State machine control logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_irq_tvalid) begin
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    state <= SEND;
                end
                
                SEND: begin
                    if (m_axis_irq_tready) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // AXI-Stream slave interface control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_irq_tready <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_irq_tready <= 1'b1;
                    if (s_axis_irq_tvalid) begin
                        s_axis_irq_tready <= 1'b0;
                    end
                end
                default: s_axis_irq_tready <= 1'b0;
            endcase
        end
    end

    // Low-level priority calculation for group 0
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            low_priority[0] <= 0;
        end else if (state == PROCESS) begin
            if (low_level_irq0[3]) low_priority[0] <= 3;
            else if (low_level_irq0[2]) low_priority[0] <= 2;
            else if (low_level_irq0[1]) low_priority[0] <= 1;
            else if (low_level_irq0[0]) low_priority[0] <= 0;
        end
    end

    // Low-level priority calculation for group 1
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            low_priority[1] <= 0;
        end else if (state == PROCESS) begin
            if (low_level_irq1[3]) low_priority[1] <= 3;
            else if (low_level_irq1[2]) low_priority[1] <= 2;
            else if (low_level_irq1[1]) low_priority[1] <= 1;
            else if (low_level_irq1[0]) low_priority[1] <= 0;
        end
    end

    // Master IRQ and vector generation
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            master_irq <= 0;
            irq_vector <= 0;
        end else if (state == PROCESS) begin
            master_irq <= |(top_level_irq & low_level_active);
            if (top_level_irq[1] && low_level_active[1])
                irq_vector <= {1'b1, low_priority[1]};
            else if (top_level_irq[0] && low_level_active[0])
                irq_vector <= {1'b0, low_priority[0]};
        end
    end

    // AXI-Stream master interface control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_irq_tvalid <= 1'b0;
            m_axis_irq_tlast <= 1'b0;
            m_axis_irq_tdata <= 0;
        end else begin
            case (state)
                SEND: begin
                    m_axis_irq_tvalid <= 1'b1;
                    m_axis_irq_tdata <= {master_irq, irq_vector};
                    m_axis_irq_tlast <= 1'b1;
                    
                    if (m_axis_irq_tready) begin
                        m_axis_irq_tvalid <= 1'b0;
                        m_axis_irq_tlast <= 1'b0;
                    end
                end
                default: begin
                    m_axis_irq_tvalid <= 1'b0;
                    m_axis_irq_tlast <= 1'b0;
                end
            endcase
        end
    end

endmodule