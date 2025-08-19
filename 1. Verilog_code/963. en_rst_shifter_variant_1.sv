//SystemVerilog
module en_rst_shifter (
    input  wire        clk,
    input  wire        rst,
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [3:0]  s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Master Interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [3:0]  m_axis_tdata,
    output wire        m_axis_tlast
);
    // Internal signals
    reg  [1:0]  mode_reg;
    reg         en_reg, serial_in_reg;
    reg  [3:0]  data_reg;
    reg  [3:0]  next_data;
    reg         m_valid_reg;
    reg         m_last_reg;
    wire        s_handshake;
    
    // Extract control signals from tdata
    wire [1:0]  mode = s_axis_tdata[3:2];
    wire        en = s_axis_tdata[1];
    wire        serial_in = s_axis_tdata[0];
    
    // Handshake signal
    assign s_handshake = s_axis_tvalid & s_axis_tready;
    
    // Always ready to receive new data
    assign s_axis_tready = m_axis_tready | ~m_valid_reg;
    
    // Output assignments
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tdata = data_reg;
    assign m_axis_tlast = m_last_reg;
    
    // Register input signals on handshake
    always @(posedge clk) begin
        if (rst) begin
            mode_reg <= 2'b00;
            en_reg <= 1'b0;
            serial_in_reg <= 1'b0;
            m_last_reg <= 1'b0;
        end
        else if (s_handshake) begin
            mode_reg <= mode;
            en_reg <= en;
            serial_in_reg <= serial_in;
            m_last_reg <= s_axis_tlast;
        end
    end
    
    // Combinational logic for next data state
    always @(*) begin
        if (en_reg) begin
            case(mode_reg)
                2'b01: next_data = {data_reg[2:0], serial_in_reg};  // Left shift
                2'b10: next_data = {serial_in_reg, data_reg[3:1]};  // Right shift
                default: next_data = data_reg;                      // Hold
            endcase
        end
        else begin
            next_data = data_reg;
        end
    end
    
    // Update data register and manage valid flag
    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 4'b0000;
            m_valid_reg <= 1'b0;
        end
        else begin
            if (s_handshake) begin
                m_valid_reg <= 1'b1;
            end
            else if (m_axis_tready) begin
                m_valid_reg <= 1'b0;
            end
            
            if (m_valid_reg && m_axis_tready) begin
                data_reg <= next_data;
            end
        end
    end
endmodule