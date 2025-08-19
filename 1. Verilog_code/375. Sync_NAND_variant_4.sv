//SystemVerilog
module Sync_NAND_AXI(
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Slave interface (input)
    input wire [15:0] s_axis_tdata,  // Combined d1 and d2, 8 bits each
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    
    // AXI-Stream Master interface (output)
    output reg [7:0] m_axis_tdata,   // Output q
    output reg m_axis_tvalid,
    input wire m_axis_tready
);

    // Internal signals
    reg [7:0] d1_reg, d2_reg;
    reg data_valid;
    reg processing_done;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam WAIT_READY = 2'b10;
    
    reg [1:0] state, next_state;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_tvalid && s_axis_tready)
                    next_state = PROCESS;
            end
            PROCESS: begin
                next_state = WAIT_READY;
            end
            WAIT_READY: begin
                if (m_axis_tready && m_axis_tvalid)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Input handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1_reg <= 8'h0;
            d2_reg <= 8'h0;
            s_axis_tready <= 1'b1;
            data_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        d1_reg <= s_axis_tdata[15:8];  // Upper 8 bits for d1
                        d2_reg <= s_axis_tdata[7:0];   // Lower 8 bits for d2
                        data_valid <= 1'b1;
                        s_axis_tready <= 1'b0;  // Not ready for new data until current data is processed
                    end else begin
                        s_axis_tready <= 1'b1;  // Ready to accept new data
                    end
                end
                WAIT_READY: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        s_axis_tready <= 1'b1;  // Ready for new data after current data is accepted
                        data_valid <= 1'b0;
                    end
                end
                default: begin
                    // maintain current values
                end
            endcase
        end
    end
    
    // Processing logic - implements the NAND function using De Morgan's Law
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 8'h0;
            processing_done <= 1'b0;
        end else if (state == PROCESS && data_valid) begin
            m_axis_tdata <= d1_reg | ~d2_reg;  // Implements d1 NAND d2
            processing_done <= 1'b1;
        end else if (state == WAIT_READY && m_axis_tready && m_axis_tvalid) begin
            processing_done <= 1'b0;
        end
    end
    
    // Output handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
        end else if (processing_done && state == WAIT_READY) begin
            m_axis_tvalid <= 1'b1;
        end else if (m_axis_tready && m_axis_tvalid) begin
            m_axis_tvalid <= 1'b0;
        end
    end

endmodule