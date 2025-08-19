module subtractor_4bit_axi_stream (
    input wire clk,           // Clock input
    input wire rst_n,         // Active-low reset
    
    // AXI-Stream Slave Interface
    input wire [3:0] s_axis_tdata,    // Input data
    input wire s_axis_tvalid,         // Input valid
    output reg s_axis_tready,         // Input ready
    
    // AXI-Stream Master Interface
    output reg [3:0] m_axis_tdata,    // Output data
    output reg m_axis_tvalid,         // Output valid
    input wire m_axis_tready          // Output ready
);

    // Internal signals
    reg [3:0] a_reg, b_reg;          // Input registers
    reg [3:0] diff_next;             // Next state for difference
    reg valid_next;                  // Next state for valid signal
    reg [1:0] state;                 // State machine state
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam RECEIVE = 2'b01;
    localparam COMPUTE = 2'b10;
    localparam SEND = 2'b11;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            valid_next <= 1'b0;
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        a_reg <= s_axis_tdata;
                        state <= RECEIVE;
                    end
                end
                
                RECEIVE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        b_reg <= s_axis_tdata;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    diff_next = a_reg - b_reg;
                    state <= SEND;
                end
                
                SEND: begin
                    if (m_axis_tready) begin
                        m_axis_tdata <= diff_next;
                        m_axis_tvalid <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // Output ready signal control
    always @(*) begin
        s_axis_tready = (state == IDLE || state == RECEIVE);
    end
    
endmodule