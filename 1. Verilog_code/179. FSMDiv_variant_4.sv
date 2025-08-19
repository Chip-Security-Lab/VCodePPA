//SystemVerilog
module FSMDiv(
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Input Interface
    input wire [15:0] s_axis_tdata,  // Input data containing dividend and divisor
    input wire s_axis_tvalid,        // Input data valid
    output wire s_axis_tready,       // Ready to accept input
    
    // AXI-Stream Output Interface
    output wire [15:0] m_axis_tdata, // Output quotient
    output wire m_axis_tvalid,       // Output data valid
    input wire m_axis_tready,        // Downstream ready to accept
    output wire m_axis_tlast         // Last data packet indicator
);
    // Internal signals
    reg [1:0] state, next_state;
    reg [15:0] rem;
    reg [15:0] quotient_reg;
    reg [15:0] divisor_reg;
    reg [4:0] cnt;
    reg operation_done;
    reg start_division;
    
    // AXI handshaking signals
    reg s_ready_reg;
    reg m_valid_reg;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam DIVIDE = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // Input handshaking
    assign s_axis_tready = s_ready_reg;
    
    // Output handshaking
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tdata = quotient_reg;
    assign m_axis_tlast = operation_done;
    
    // State machine - sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rem <= 16'b0;
            quotient_reg <= 16'b0;
            divisor_reg <= 16'b0;
            cnt <= 5'b0;
            operation_done <= 1'b0;
            s_ready_reg <= 1'b1;
            m_valid_reg <= 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    operation_done <= 1'b0;
                    if (s_axis_tvalid && s_ready_reg) begin
                        // Extract dividend and divisor from s_axis_tdata
                        // Assuming high 16 bits are dividend, low 16 bits are divisor
                        rem <= s_axis_tdata;
                        divisor_reg <= s_axis_tdata >> 16;  // Divisor is in upper bits
                        cnt <= 5'd15;
                        quotient_reg <= 16'b0;
                        s_ready_reg <= 1'b0;  // Not ready for new data
                        state <= DIVIDE;
                    end else begin
                        s_ready_reg <= 1'b1;  // Ready to accept new data
                    end
                end
                
                DIVIDE: begin
                    rem <= rem << 1;
                    if (rem >= divisor_reg) begin
                        rem <= rem - divisor_reg;
                        quotient_reg[cnt] <= 1'b1;
                    end
                    
                    if (cnt == 0) begin
                        state <= COMPLETE;
                        operation_done <= 1'b1;
                        m_valid_reg <= 1'b1;  // Output is valid
                    end else begin
                        cnt <= cnt - 1;
                    end
                end
                
                COMPLETE: begin
                    if (m_axis_tready && m_valid_reg) begin
                        m_valid_reg <= 1'b0;
                        s_ready_reg <= 1'b1;
                        operation_done <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule