module pipelined_adder_axi_stream (
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Slave Interface
    input wire [7:0] s_axis_tdata_a,
    input wire s_axis_tvalid_a,
    output reg s_axis_tready_a,
    
    input wire [7:0] s_axis_tdata_b,
    input wire s_axis_tvalid_b,
    output reg s_axis_tready_b,
    
    // AXI-Stream Master Interface
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);

    // Carry Look-ahead Adder signals
    reg [7:0] a_reg, b_reg;
    reg valid_stage1, valid_stage2;
    
    // Generate and Propagate signals
    wire [7:0] g, p;
    wire [8:0] c;  // Carry signals (includes initial carry-in)
    reg [7:0] sum_reg;
    
    // Stage 1: Input Registers and Generate/Propagate calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            valid_stage1 <= 1'b0;
            s_axis_tready_a <= 1'b1;
            s_axis_tready_b <= 1'b1;
        end else begin
            if (s_axis_tvalid_a && s_axis_tvalid_b) begin
                a_reg <= s_axis_tdata_a;
                b_reg <= s_axis_tdata_b;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Generate and Propagate signals
    assign g = a_reg & b_reg;                // Generate
    assign p = a_reg ^ b_reg;                // Propagate
    
    // Carry calculation using carry look-ahead logic
    assign c[0] = 1'b0;                      // Initial carry-in is 0
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[4]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c[4]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & c[4]);
    
    // Stage 2: Sum calculation and Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg <= 8'b0;
            m_axis_tdata <= 8'b0;
            m_axis_tvalid <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1 && m_axis_tready) begin
                // Sum calculation using carry look-ahead adder
                sum_reg <= p ^ c[7:0];
                m_axis_tdata <= p ^ c[7:0];
                m_axis_tvalid <= 1'b1;
                valid_stage2 <= 1'b1;
            end else if (!m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule