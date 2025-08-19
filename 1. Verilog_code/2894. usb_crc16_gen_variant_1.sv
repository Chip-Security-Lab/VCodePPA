//SystemVerilog
module usb_crc16_gen(
    input  logic        aclk,
    input  logic        aresetn,
    
    // AXI-Stream Slave Interface
    input  logic [7:0]  s_axis_tdata,
    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    input  logic        s_axis_tlast,
    
    // AXI-Stream Master Interface
    output logic [15:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast
);
    // Internal registers for CRC calculation
    logic [15:0] crc_reg;
    logic [15:0] next_crc;
    logic processing_data;
    
    // Handshaking control
    assign s_axis_tready = !processing_data || m_axis_tready;
    
    // CRC calculation logic
    wire xor_all_data;  // 所有数据位的异或结果
    wire [7:0] xor_cascade; // 级联异或中间结果
    
    // 使用级联结构计算所有数据位的异或，减少逻辑深度
    assign xor_cascade[0] = s_axis_tdata[0] ^ s_axis_tdata[1];
    assign xor_cascade[1] = xor_cascade[0] ^ s_axis_tdata[2];
    assign xor_cascade[2] = xor_cascade[1] ^ s_axis_tdata[3];
    assign xor_cascade[3] = xor_cascade[2] ^ s_axis_tdata[4];
    assign xor_cascade[4] = xor_cascade[3] ^ s_axis_tdata[5];
    assign xor_cascade[5] = xor_cascade[4] ^ s_axis_tdata[6];
    assign xor_cascade[6] = xor_cascade[5] ^ s_axis_tdata[7];
    assign xor_all_data = xor_cascade[6];
    
    // 高位CRC部分的异或结果
    wire xor_high_crc;
    wire [7:0] crc_cascade;
    
    assign crc_cascade[0] = crc_reg[8] ^ crc_reg[9];
    assign crc_cascade[1] = crc_cascade[0] ^ crc_reg[10];
    assign crc_cascade[2] = crc_cascade[1] ^ crc_reg[11];
    assign crc_cascade[3] = crc_cascade[2] ^ crc_reg[12];
    assign crc_cascade[4] = crc_cascade[3] ^ crc_reg[13];
    assign crc_cascade[5] = crc_cascade[4] ^ crc_reg[14];
    assign crc_cascade[6] = crc_cascade[5] ^ crc_reg[15];
    assign xor_high_crc = crc_cascade[6];
    
    // CRC computation
    assign next_crc[0] = xor_all_data ^ xor_high_crc;
    assign next_crc[1] = xor_all_data ^ xor_high_crc ^ s_axis_tdata[0];
    assign next_crc[2] = s_axis_tdata[0] ^ s_axis_tdata[1] ^ crc_reg[8] ^ crc_reg[10] ^ crc_reg[11] ^ crc_reg[12] ^ crc_reg[13] ^ crc_reg[14] ^ crc_reg[15];
    assign next_crc[3] = s_axis_tdata[1] ^ s_axis_tdata[2] ^ crc_reg[9] ^ crc_reg[11] ^ crc_reg[12] ^ crc_reg[13] ^ crc_reg[14] ^ crc_reg[15];
    assign next_crc[4] = s_axis_tdata[2] ^ s_axis_tdata[3] ^ crc_reg[10] ^ crc_reg[12] ^ crc_reg[13] ^ crc_reg[14] ^ crc_reg[15];
    assign next_crc[5] = s_axis_tdata[3] ^ s_axis_tdata[4] ^ crc_reg[11] ^ crc_reg[13] ^ crc_reg[14] ^ crc_reg[15];
    assign next_crc[6] = s_axis_tdata[4] ^ s_axis_tdata[5] ^ crc_reg[12] ^ crc_reg[14] ^ crc_reg[15];
    assign next_crc[7] = s_axis_tdata[5] ^ s_axis_tdata[6] ^ crc_reg[13] ^ crc_reg[15];
    assign next_crc[8] = s_axis_tdata[6] ^ s_axis_tdata[7] ^ crc_reg[0] ^ crc_reg[14];
    assign next_crc[9] = s_axis_tdata[7] ^ crc_reg[1] ^ crc_reg[15];
    assign next_crc[10] = crc_reg[2];
    assign next_crc[11] = crc_reg[3];
    assign next_crc[12] = crc_reg[4];
    assign next_crc[13] = crc_reg[5];
    assign next_crc[14] = crc_reg[6];
    assign next_crc[15] = crc_reg[7] ^ s_axis_tdata[0] ^ s_axis_tdata[1] ^ s_axis_tdata[2] ^ s_axis_tdata[3] ^ 
                          s_axis_tdata[4] ^ s_axis_tdata[5] ^ s_axis_tdata[6] ^ s_axis_tdata[7] ^ crc_reg[8] ^ 
                          crc_reg[9] ^ crc_reg[10] ^ crc_reg[11] ^ crc_reg[12] ^ crc_reg[13] ^ 
                          crc_reg[14] ^ crc_reg[15];
                   
    // Sequential logic for CRC processing
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            crc_reg <= 16'h0000;
            processing_data <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                // Process new data
                crc_reg <= next_crc;
                processing_data <= 1'b1;
                
                // Forward last signal
                if (s_axis_tlast) begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= 1'b1;
                end
            end else if (processing_data && m_axis_tready) begin
                // Data has been accepted downstream
                processing_data <= 1'b0;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                crc_reg <= 16'h0000; // Reset CRC for next data packet
            end
        end
    end
    
    // Output assignment
    assign m_axis_tdata = crc_reg;
    
endmodule