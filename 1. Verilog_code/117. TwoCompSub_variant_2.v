module TwoCompSub_AXIS (
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    
    // AXI-Stream Master Interface
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);

    // Internal signals
    reg [7:0] a_reg, b_reg;
    wire [7:0] res_wire;
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam WAIT = 2'b10;
    
    // Brent-Kung adder implementation
    wire [7:0] b_comp;
    wire [7:0] g, p;
    wire [7:0] c;
    
    // Two's complement calculation
    assign b_comp = ~b_reg + 1'b1;
    
    // Generate and propagate signals
    assign g = a_reg & b_comp;
    assign p = a_reg ^ b_comp;
    
    // Brent-Kung adder implementation
    wire [3:0] g_2bit, p_2bit;
    assign g_2bit[0] = g[1] | (p[1] & g[0]);
    assign p_2bit[0] = p[1] & p[0];
    assign g_2bit[1] = g[3] | (p[3] & g[2]);
    assign p_2bit[1] = p[3] & p[2];
    assign g_2bit[2] = g[5] | (p[5] & g[4]);
    assign p_2bit[2] = p[5] & p[4];
    assign g_2bit[3] = g[7] | (p[7] & g[6]);
    assign p_2bit[3] = p[7] & p[6];
    
    wire [1:0] g_4bit, p_4bit;
    assign g_4bit[0] = g_2bit[1] | (p_2bit[1] & g_2bit[0]);
    assign p_4bit[0] = p_2bit[1] & p_2bit[0];
    assign g_4bit[1] = g_2bit[3] | (p_2bit[3] & g_2bit[2]);
    assign p_4bit[1] = p_2bit[3] & p_2bit[2];
    
    wire g_8bit, p_8bit;
    assign g_8bit = g_4bit[1] | (p_4bit[1] & g_4bit[0]);
    assign p_8bit = p_4bit[1] & p_4bit[0];
    
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g_2bit[0];
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g_4bit[0];
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g_8bit;
    
    assign res_wire = p ^ {c[6:0], 1'b0};
    
    // State machine and control logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            m_axis_tdata <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid) begin
                        a_reg <= s_axis_tdata;
                        s_axis_tready <= 1'b0;
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    if (s_axis_tvalid) begin
                        b_reg <= s_axis_tdata;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tdata <= res_wire;
                        m_axis_tlast <= 1'b1;
                        state <= WAIT;
                    end
                end
                
                WAIT: begin
                    if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        s_axis_tready <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule