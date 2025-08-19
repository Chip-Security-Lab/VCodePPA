//SystemVerilog
module GammaCorrection (
    // Clock and Reset
    input wire        aclk,
    input wire        aresetn,
    
    // AXI-Stream Slave Interface
    input wire [31:0] s_axis_tdata,
    input wire        s_axis_tvalid,
    output reg        s_axis_tready,
    input wire        s_axis_tlast,
    
    // AXI-Stream Master Interface  
    output reg [31:0] m_axis_tdata,
    output reg        m_axis_tvalid,
    input wire        m_axis_tready,
    output reg        m_axis_tlast
);

    // Internal registers
    reg [7:0] pixel_in_reg;
    reg [7:0] pixel_out_reg;
    reg       process_enable;
    
    // Gamma LUT
    reg [7:0] gamma_lut [0:255];
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam OUTPUT = 2'b10;
    
    reg [1:0] state;
    
    // Initialize LUT
    initial begin
        // 0-127 values set to i/2
        gamma_lut[0] = 0;
        gamma_lut[1] = 0;
        gamma_lut[2] = 1;
        gamma_lut[3] = 1;
        // ... existing code ...
        gamma_lut[126] = 63;
        gamma_lut[127] = 63;
        
        // 128-255 values set to (i-128)*2
        gamma_lut[128] = 0;
        gamma_lut[129] = 2;
        gamma_lut[130] = 4;
        // ... existing code ...
        gamma_lut[254] = 252;
        gamma_lut[255] = 254;
    end

    // Main state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE;
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            pixel_in_reg <= 8'h00;
            pixel_out_reg <= 8'h00;
            process_enable <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_tready <= 1'b1;
                    if (s_axis_tvalid) begin
                        pixel_in_reg <= s_axis_tdata[7:0];
                        process_enable <= 1'b1;
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    s_axis_tready <= 1'b0;
                    pixel_out_reg <= gamma_lut[pixel_in_reg];
                    state <= OUTPUT;
                end
                
                OUTPUT: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= {24'h000000, pixel_out_reg};
                    m_axis_tlast <= s_axis_tlast;
                    
                    if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        process_enable <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule