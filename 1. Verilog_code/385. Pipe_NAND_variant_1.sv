//SystemVerilog
module Pipe_NAND (
    // Clock and reset
    input wire        clk,
    input wire        rst_n,  // Active low reset added
    
    // Input AXI-Stream interface
    input wire [15:0] s_axis_tdata,  // Input data
    input wire        s_axis_tvalid,  // Input valid signal
    input wire        s_axis_tlast,   // Input last signal
    output wire       s_axis_tready,  // Output ready signal
    
    // Output AXI-Stream interface
    output wire [15:0] m_axis_tdata,   // Output data
    output wire        m_axis_tvalid,  // Output valid signal
    output wire        m_axis_tlast,   // Output last signal
    input wire        m_axis_tready   // Input ready signal
);

    // Internal signals
    reg [15:0] a_reg, b_reg;
    reg        data_valid;
    reg        last_reg;
    
    // NAND operation moved before register
    wire [15:0] nand_result;
    assign nand_result = ~(a_reg & b_reg);
    
    // Output registers
    reg [15:0] m_axis_tdata_reg;
    reg        m_axis_tvalid_reg;
    reg        m_axis_tlast_reg;
    
    // Connect output registers to output ports
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    
    // Input ready signal generation - ready when downstream is ready or output is not valid
    assign s_axis_tready = !m_axis_tvalid_reg || m_axis_tready;
    
    // Input data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'b0;
            b_reg <= 16'b0;
            data_valid <= 1'b0;
            last_reg <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            // Pack the 16-bit input data into a_reg and b_reg
            a_reg <= s_axis_tdata;
            b_reg <= a_reg;
            data_valid <= 1'b1;
            last_reg <= s_axis_tlast;
        end else if (m_axis_tready) begin
            data_valid <= 1'b0;
        end
    end
    
    // Output data generation - register NAND result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata_reg <= 16'b0;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
        end else if (data_valid && (m_axis_tready || !m_axis_tvalid_reg)) begin
            m_axis_tdata_reg <= nand_result;  // Register pre-computed NAND result
            m_axis_tvalid_reg <= 1'b1;
            m_axis_tlast_reg <= last_reg;
        end else if (m_axis_tready) begin
            m_axis_tvalid_reg <= 1'b0;
        end
    end
    
endmodule