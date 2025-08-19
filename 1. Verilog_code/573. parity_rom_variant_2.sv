//SystemVerilog
module parity_rom (
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave interface
    input wire [3:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // AXI-Stream Master interface
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast,
    output reg [0:0] m_axis_tuser,  // For parity error indication
    input wire m_axis_tready
);

    // ROM with parity bit (9 bits total)
    (* ram_style = "distributed" *) reg [8:0] rom [0:15];
    
    // Pipeline registers for improved timing
    reg [3:0] addr_pipeline;
    reg addr_valid;
    reg addr_last;
    
    // FSM states
    localparam IDLE = 2'b00,
               FETCH = 2'b01,
               TRANSMIT = 2'b10;
    
    reg [1:0] state, next_state;
    
    // ROM initialization
    initial begin
        rom[0] = 9'b000100010; // Data = 0x12, Parity = 0
        rom[1] = 9'b001101000; // Data = 0x34, Parity = 0
        rom[2] = 9'b010101101; // Data = 0x56, Parity = 1
        rom[3] = 9'b011110000; // Data = 0x78, Parity = 0
        rom[4] = 9'b100100101; // Data = 0x9A, Parity = 1
        rom[5] = 9'b101101111; // Data = 0xBC, Parity = 1
        rom[6] = 9'b110101010; // Data = 0xDE, Parity = 0
        rom[7] = 9'b111110110; // Data = 0xF0, Parity = 0
        rom[8] = 9'b000011010; // Data = 0x1A, Parity = 0
        rom[9] = 9'b001010100; // Data = 0x28, Parity = 0
        rom[10] = 9'b010011001; // Data = 0x4C, Parity = 1
        rom[11] = 9'b011010011; // Data = 0x53, Parity = 1
        rom[12] = 9'b100011110; // Data = 0x9E, Parity = 0
        rom[13] = 9'b101010001; // Data = 0xA1, Parity = 1
        rom[14] = 9'b110011101; // Data = 0xCD, Parity = 1
        rom[15] = 9'b111010010; // Data = 0xE4, Parity = 0
    end

    // Optimized AXI-Stream ready signal
    assign s_axis_tready = (state == IDLE) || 
                          ((state == TRANSMIT) && m_axis_tready && m_axis_tvalid);
    
    // State machine - sequential logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            addr_pipeline <= 4'b0;
            addr_valid <= 1'b0;
            addr_last <= 1'b0;
            m_axis_tdata <= 8'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tuser <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        addr_pipeline <= s_axis_tdata;
                        addr_valid <= 1'b1;
                        addr_last <= s_axis_tlast;
                        state <= FETCH;
                    end
                end
                
                FETCH: begin
                    // ROM lookup cycle
                    m_axis_tdata <= rom[addr_pipeline][7:0];
                    m_axis_tuser[0] <= (rom[addr_pipeline][8] != ^rom[addr_pipeline][7:0]);
                    m_axis_tvalid <= addr_valid;
                    m_axis_tlast <= addr_last;
                    addr_valid <= 1'b0;
                    state <= TRANSMIT;
                end
                
                TRANSMIT: begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Performance optimizations
    // Synthesis attributes for timing improvement
    (* keep = "true" *) reg [8:0] rom_data;
    
    // Prefetch ROM data to reduce critical path
    always @(posedge aclk) begin
        if (state == IDLE && s_axis_tvalid)
            rom_data <= rom[s_axis_tdata];
    end
    
endmodule