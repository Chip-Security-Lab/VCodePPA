//SystemVerilog
// IEEE 1364-2005 Verilog standard
module shift_reg_4bit_axi (
    input wire clk,
    input wire rst,
    
    // AXI-Stream input interface
    input wire [3:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // AXI-Stream output interface
    output wire [3:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready,
    
    // Serial interface
    input wire serial_in,
    output wire serial_out
);
    
    reg [3:0] sr;
    reg s_ready_reg;
    reg m_valid_reg;
    reg m_last_reg;
    
    // Create control signals with lookup tables
    reg [3:0] current_state;
    wire [3:0] next_state;
    wire [2:0] control_signals; // {load_en, shift_en, s_ready}
    
    // State encoding
    localparam [3:0] IDLE          = 4'b0001,
                     LOAD_DATA     = 4'b0010,
                     SHIFT_DATA    = 4'b0100,
                     WAIT_READY    = 4'b1000;
    
    // Control LUT for {load_en, shift_en, s_ready} based on current state and inputs
    // Format: {s_axis_tvalid, s_axis_tlast, m_axis_tready, m_valid_reg}
    function [2:0] control_lut;
        input [3:0] state;
        input [3:0] conditions;
        begin
            case ({state, conditions})
                // IDLE state
                {IDLE, 4'b0000}: control_lut = 3'b001; // Ready for input
                {IDLE, 4'b0001}: control_lut = 3'b001; // Ready for input
                {IDLE, 4'b0010}: control_lut = 3'b011; // Ready for input, can shift
                {IDLE, 4'b0011}: control_lut = 3'b011; // Ready for input, can shift
                {IDLE, 4'b1000}: control_lut = 3'b001; // Ready for input
                {IDLE, 4'b1001}: control_lut = 3'b001; // Ready for input
                {IDLE, 4'b1010}: control_lut = 3'b011; // Ready for input, can shift
                {IDLE, 4'b1011}: control_lut = 3'b011; // Ready for input, can shift
                {IDLE, 4'b1100}: control_lut = 3'b101; // Valid data with last, load
                {IDLE, 4'b1101}: control_lut = 3'b101; // Valid data with last, load
                {IDLE, 4'b1110}: control_lut = 3'b111; // Valid data with last, load and shift
                {IDLE, 4'b1111}: control_lut = 3'b111; // Valid data with last, load and shift
                
                // LOAD_DATA state
                {LOAD_DATA, 4'b??10}: control_lut = 3'b011; // Can shift if ready
                {LOAD_DATA, 4'b??11}: control_lut = 3'b011; // Can shift if ready
                {LOAD_DATA, 4'b??00}: control_lut = 3'b000; // Wait
                {LOAD_DATA, 4'b??01}: control_lut = 3'b000; // Wait
                
                // SHIFT_DATA state
                {SHIFT_DATA, 4'b??10}: control_lut = 3'b011; // Can shift if ready
                {SHIFT_DATA, 4'b??11}: control_lut = 3'b011; // Can shift if ready
                {SHIFT_DATA, 4'b??00}: control_lut = 3'b000; // Wait
                {SHIFT_DATA, 4'b??01}: control_lut = 3'b000; // Wait
                
                // WAIT_READY state
                {WAIT_READY, 4'b??10}: control_lut = 3'b011; // Ready for output and can shift
                {WAIT_READY, 4'b??11}: control_lut = 3'b011; // Ready for output and can shift
                {WAIT_READY, 4'b??00}: control_lut = 3'b000; // Wait
                {WAIT_READY, 4'b??01}: control_lut = 3'b000; // Wait
                
                default: control_lut = 3'b001;       // Default: Ready for input
            endcase
        end
    endfunction
    
    // Next state LUT
    function [3:0] next_state_lut;
        input [3:0] state;
        input [3:0] conditions;
        begin
            case ({state, conditions})
                // IDLE state transitions
                {IDLE, 4'b0???}: next_state_lut = IDLE;           // Stay in IDLE if no valid input
                {IDLE, 4'b11??}: next_state_lut = LOAD_DATA;      // Valid data with last, go to LOAD
                {IDLE, 4'b10??}: next_state_lut = IDLE;           // Valid but not last, stay in IDLE
                
                // LOAD_DATA state transitions
                {LOAD_DATA, 4'b??10}: next_state_lut = SHIFT_DATA;   // Ready, go to SHIFT
                {LOAD_DATA, 4'b??00}: next_state_lut = WAIT_READY;   // Not ready, go to WAIT
                {LOAD_DATA, 4'b??11}: next_state_lut = IDLE;         // Ready and valid, back to IDLE
                {LOAD_DATA, 4'b??01}: next_state_lut = WAIT_READY;   // Valid but not ready, go to WAIT
                
                // SHIFT_DATA state transitions
                {SHIFT_DATA, 4'b????}: next_state_lut = IDLE;     // Always return to IDLE after shift
                
                // WAIT_READY state transitions
                {WAIT_READY, 4'b??1?}: next_state_lut = IDLE;     // Ready, go back to IDLE
                {WAIT_READY, 4'b??0?}: next_state_lut = WAIT_READY; // Not ready, keep waiting
                
                default: next_state_lut = IDLE;                   // Default to IDLE
            endcase
        end
    endfunction
    
    // Current state conditions
    wire [3:0] current_conditions = {s_axis_tvalid, s_axis_tlast, m_axis_tready, m_valid_reg};
    
    // Lookup control signals and next state
    assign control_signals = control_lut(current_state, current_conditions);
    assign next_state = next_state_lut(current_state, current_conditions);
    
    // Decode control signals
    wire load_en = control_signals[2];
    wire shift_en = control_signals[1];
    wire s_ready = control_signals[0];
    
    // Connect to outputs
    assign s_axis_tready = s_ready;
    assign m_axis_tdata = sr;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_last_reg;
    assign serial_out = sr[3];
    
    // State register
    always @(posedge clk) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // Ready register
    always @(posedge clk) begin
        if (rst)
            s_ready_reg <= 1'b0;
        else
            s_ready_reg <= s_ready;
    end
    
    // Valid register with lookup-based control
    always @(posedge clk) begin
        if (rst)
            m_valid_reg <= 1'b0;
        else if (load_en || shift_en)
            m_valid_reg <= 1'b1;
        else if (m_axis_tready)
            m_valid_reg <= 1'b0;
    end
    
    // Last signal register
    always @(posedge clk) begin
        if (rst)
            m_last_reg <= 1'b0;
        else if (s_axis_tvalid && s_ready)
            m_last_reg <= s_axis_tlast;
    end
    
    // Shift register with lookup-based control
    always @(posedge clk) begin
        if (rst)
            sr <= 4'b0000;
        else if (load_en)
            sr <= s_axis_tdata;
        else if (shift_en)
            sr <= {sr[2:0], serial_in};
    end
    
endmodule