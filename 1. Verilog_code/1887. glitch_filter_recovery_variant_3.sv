//SystemVerilog
module glitch_filter_recovery (
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream slave interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [0:0] s_axis_tdata, // Single bit input
    
    // AXI-Stream master interface
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [0:0] m_axis_tdata  // Single bit output
);
    // Pipeline stage 1: Input handling and shift register
    reg [3:0] shift_reg_stage1;
    reg valid_stage1;
    reg [0:0] data_stage1;
    
    // Pipeline stage 2: Glitch filtering algorithm
    reg clean_signal_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Output handling
    
    // Always accept input data when valid
    assign s_axis_tready = 1'b1;
    
    // Pipeline stage 1 - Input capture and shift register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
            data_stage1 <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                shift_reg_stage1 <= {shift_reg_stage1[2:0], s_axis_tdata[0]};
                valid_stage1 <= 1'b1;
                data_stage1 <= s_axis_tdata;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2 - Apply glitch filtering algorithm
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                case (shift_reg_stage1)
                    4'b0000: clean_signal_stage2 <= 1'b0;
                    4'b0001: clean_signal_stage2 <= clean_signal_stage2;
                    4'b0010: clean_signal_stage2 <= clean_signal_stage2;
                    4'b0011: clean_signal_stage2 <= clean_signal_stage2;
                    4'b0100: clean_signal_stage2 <= clean_signal_stage2;
                    4'b0101: clean_signal_stage2 <= clean_signal_stage2;
                    4'b0110: clean_signal_stage2 <= clean_signal_stage2;
                    4'b0111: clean_signal_stage2 <= 1'b1;
                    4'b1000: clean_signal_stage2 <= clean_signal_stage2;
                    4'b1001: clean_signal_stage2 <= clean_signal_stage2;
                    4'b1010: clean_signal_stage2 <= clean_signal_stage2;
                    4'b1011: clean_signal_stage2 <= 1'b1;
                    4'b1100: clean_signal_stage2 <= clean_signal_stage2;
                    4'b1101: clean_signal_stage2 <= 1'b1;
                    4'b1110: clean_signal_stage2 <= 1'b1;
                    4'b1111: clean_signal_stage2 <= 1'b1;
                endcase
            end
        end
    end
    
    // Pipeline stage 3 - Output handling with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 1'b0;
        end else begin
            // If there is new filtered data and output is not valid yet or was just accepted
            if (valid_stage2 && (!m_axis_tvalid || m_axis_tready)) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata <= clean_signal_stage2;
            // If output is valid and consumer accepted it, clear valid flag
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end
endmodule