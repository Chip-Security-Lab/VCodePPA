//SystemVerilog
//IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module pause_frame_gen #(
    parameter QUANTUM = 16'hFFFF,
    parameter THRESHOLD = 16'h00FF
)(
    input wire clk,
    input wire rst,
    input wire pause_req,
    input wire [15:0] rx_pause,
    output wire [7:0] tx_data,
    output wire tx_valid,
    output wire tx_enable
);
    // Constants for Ethernet frame
    localparam [95:0] PAUSE_MAC = {
        8'h01, 8'h80, 8'hC2, 8'h00, 8'h00, 8'h01,  // Destination MAC (Multicast)
        8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55   // Source MAC
    };
    
    localparam [15:0] ETH_TYPE_VAL = 16'h8808;  // Ethernet Type for PAUSE frame
    localparam [15:0] PAUSE_OPCODE = 16'h0001;  // PAUSE opcode
    
    // Internal signals
    wire pause_condition;
    wire [3:0] state;
    wire [3:0] byte_cnt;
    wire [31:0] crc;
    wire [7:0] tx_data_int;
    wire tx_valid_int;
    wire tx_enable_int;
    
    // Instantiate input processor module
    pause_frame_input_processor u_input_processor (
        .clk(clk),
        .rst(rst),
        .pause_req(pause_req),
        .rx_pause(rx_pause),
        .threshold(THRESHOLD),
        .pause_condition(pause_condition)
    );
    
    // Instantiate state controller module
    pause_frame_state_controller u_state_controller (
        .clk(clk),
        .rst(rst),
        .pause_condition(pause_condition),
        .state(state),
        .byte_cnt(byte_cnt)
    );
    
    // Instantiate data path module
    pause_frame_datapath u_datapath (
        .clk(clk),
        .rst(rst),
        .state(state),
        .byte_cnt(byte_cnt),
        .pause_mac(PAUSE_MAC),
        .eth_type_val(ETH_TYPE_VAL),
        .pause_opcode(PAUSE_OPCODE),
        .quantum(QUANTUM),
        .crc(crc),
        .tx_data(tx_data_int),
        .tx_valid(tx_valid_int),
        .tx_enable(tx_enable_int)
    );
    
    // Instantiate CRC generator module
    pause_frame_crc_gen u_crc_gen (
        .clk(clk),
        .rst(rst),
        .state(state),
        .byte_cnt(byte_cnt),
        .tx_data(tx_data_int),
        .crc(crc)
    );
    
    // Instantiate output register module
    pause_frame_output_reg u_output_reg (
        .clk(clk),
        .rst(rst),
        .tx_data_in(tx_data_int),
        .tx_valid_in(tx_valid_int),
        .tx_enable_in(tx_enable_int),
        .tx_data_out(tx_data),
        .tx_valid_out(tx_valid),
        .tx_enable_out(tx_enable)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Input Processor Module
///////////////////////////////////////////////////////////////////////////////
module pause_frame_input_processor (
    input wire clk,
    input wire rst,
    input wire pause_req,
    input wire [15:0] rx_pause,
    input wire [15:0] threshold,
    output wire pause_condition
);
    // Pause condition detection
    assign pause_condition = pause_req || (rx_pause > threshold);
    
    // Registered inputs (not used for pause_condition)
    reg pause_req_ff1;
    reg [15:0] rx_pause_ff1;
    
    // Register inputs for other usage if needed
    always @(posedge clk) begin
        if (rst) begin
            pause_req_ff1 <= 1'b0;
            rx_pause_ff1 <= 16'h0;
        end else begin
            pause_req_ff1 <= pause_req;
            rx_pause_ff1 <= rx_pause;
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// State Controller Module
///////////////////////////////////////////////////////////////////////////////
module pause_frame_state_controller (
    input wire clk,
    input wire rst,
    input wire pause_condition,
    output reg [3:0] state,
    output reg [3:0] byte_cnt
);
    // State machine encoding
    localparam IDLE       = 4'h0;
    localparam PREAMBLE   = 4'h1; 
    localparam MAC_HEADER = 4'h3;
    localparam ETH_TYPE   = 4'h4;
    localparam OPCODE     = 4'h5;
    localparam QUANTUM_VAL = 4'h6;
    localparam FCS        = 4'h7;
    localparam HOLD       = 4'h8;
    
    // State and control registers
    reg [3:0] state_next;
    reg [3:0] byte_cnt_next;
    reg [15:0] pause_timer, pause_timer_next;
    
    // State machine next state logic
    always @(*) begin
        // Default: maintain current values
        state_next = state;
        byte_cnt_next = byte_cnt;
        pause_timer_next = pause_timer;
        
        case (state)
            IDLE: begin
                if (pause_condition) begin
                    state_next = PREAMBLE;
                    byte_cnt_next = 4'h0;
                end
            end
            
            PREAMBLE: begin
                if (byte_cnt == 7) begin
                    state_next = MAC_HEADER;
                    byte_cnt_next = 4'h0;
                end else begin
                    byte_cnt_next = byte_cnt + 4'h1;
                end
            end
            
            MAC_HEADER: begin
                if (byte_cnt == 11) begin
                    state_next = ETH_TYPE;
                    byte_cnt_next = 4'h0;
                end else begin
                    byte_cnt_next = byte_cnt + 4'h1;
                end
            end
            
            ETH_TYPE: begin
                if (byte_cnt == 1) begin
                    state_next = OPCODE;
                    byte_cnt_next = 4'h0;
                end else begin
                    byte_cnt_next = byte_cnt + 4'h1;
                end
            end
            
            OPCODE: begin
                if (byte_cnt == 1) begin
                    state_next = QUANTUM_VAL;
                    byte_cnt_next = 4'h0;
                end else begin
                    byte_cnt_next = byte_cnt + 4'h1;
                end
            end
            
            QUANTUM_VAL: begin
                if (byte_cnt == 1) begin
                    state_next = FCS;
                    byte_cnt_next = 4'h0;
                end else begin
                    byte_cnt_next = byte_cnt + 4'h1;
                end
            end
            
            FCS: begin
                if (byte_cnt == 3) begin
                    state_next = HOLD;
                    byte_cnt_next = 4'h0;
                    pause_timer_next = 16'h0;
                end else begin
                    byte_cnt_next = byte_cnt + 4'h1;
                end
            end
            
            HOLD: begin
                if (pause_timer == 16'hFFFF) begin
                    state_next = IDLE;
                end else begin
                    pause_timer_next = pause_timer + 16'h1;
                end
            end
            
            default: begin
                state_next = IDLE;
            end
        endcase
    end
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            byte_cnt <= 4'h0;
            pause_timer <= 16'h0;
        end else begin
            state <= state_next;
            byte_cnt <= byte_cnt_next;
            pause_timer <= pause_timer_next;
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Datapath Module
///////////////////////////////////////////////////////////////////////////////
module pause_frame_datapath (
    input wire clk,
    input wire rst,
    input wire [3:0] state,
    input wire [3:0] byte_cnt,
    input wire [95:0] pause_mac,
    input wire [15:0] eth_type_val,
    input wire [15:0] pause_opcode,
    input wire [15:0] quantum,
    input wire [31:0] crc,
    output reg [7:0] tx_data,
    output reg tx_valid,
    output reg tx_enable
);
    // State machine encoding
    localparam IDLE       = 4'h0;
    localparam PREAMBLE   = 4'h1; 
    localparam MAC_HEADER = 4'h3;
    localparam ETH_TYPE   = 4'h4;
    localparam OPCODE     = 4'h5;
    localparam QUANTUM_VAL = 4'h6;
    localparam FCS        = 4'h7;
    localparam HOLD       = 4'h8;
    
    // Next state signals
    reg [7:0] tx_data_next;
    reg tx_valid_next;
    reg tx_enable_next;
    
    // Datapath next value logic
    always @(*) begin
        tx_data_next = tx_data;
        tx_valid_next = 1'b0;  // Default invalid
        tx_enable_next = tx_enable;
        
        case (state)
            IDLE: begin
                tx_enable_next = 1'b0;
                if (state == IDLE && state != PREAMBLE) begin
                    tx_enable_next = 1'b1;
                end
            end
            
            PREAMBLE: begin
                tx_valid_next = 1'b1;
                tx_data_next = (byte_cnt < 7) ? 8'h55 : 8'hD5;  // SFD at end of preamble
                tx_enable_next = 1'b1;
            end
            
            MAC_HEADER: begin
                tx_valid_next = 1'b1;
                tx_data_next = pause_mac[8*byte_cnt +: 8];
            end
            
            ETH_TYPE: begin
                tx_valid_next = 1'b1;
                tx_data_next = (byte_cnt == 0) ? eth_type_val[15:8] : eth_type_val[7:0];
            end
            
            OPCODE: begin
                tx_valid_next = 1'b1;
                tx_data_next = (byte_cnt == 0) ? pause_opcode[15:8] : pause_opcode[7:0];
            end
            
            QUANTUM_VAL: begin
                tx_valid_next = 1'b1;
                tx_data_next = (byte_cnt == 0) ? quantum[15:8] : quantum[7:0];
            end
            
            FCS: begin
                tx_valid_next = 1'b1;
                case (byte_cnt)
                    4'h0: tx_data_next = ~crc[31:24];
                    4'h1: tx_data_next = ~crc[23:16];
                    4'h2: tx_data_next = ~crc[15:8];
                    4'h3: tx_data_next = ~crc[7:0];
                    default: tx_data_next = 8'h00;
                endcase
            end
            
            HOLD: begin
                tx_valid_next = 1'b0;
                tx_enable_next = 1'b0;
            end
            
            default: begin
                tx_valid_next = 1'b0;
                tx_enable_next = 1'b0;
            end
        endcase
    end
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst) begin
            tx_data <= 8'h0;
            tx_valid <= 1'b0;
            tx_enable <= 1'b0;
        end else begin
            tx_data <= tx_data_next;
            tx_valid <= tx_valid_next;
            tx_enable <= tx_enable_next;
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// CRC Generator Module
///////////////////////////////////////////////////////////////////////////////
module pause_frame_crc_gen (
    input wire clk,
    input wire rst,
    input wire [3:0] state,
    input wire [3:0] byte_cnt,
    input wire [7:0] tx_data,
    output reg [31:0] crc
);
    // State machine encoding
    localparam IDLE       = 4'h0;
    localparam PREAMBLE   = 4'h1; 
    localparam MAC_HEADER = 4'h3;
    localparam ETH_TYPE   = 4'h4;
    localparam OPCODE     = 4'h5;
    localparam QUANTUM_VAL = 4'h6;
    localparam FCS        = 4'h7;
    localparam HOLD       = 4'h8;
    
    // CRC polynomial
    localparam CRC32_POLY = 32'h04C11DB7;
    
    // CRC calculation registers
    reg [31:0] crc_next;
    wire [31:0] crc_update;
    
    ///////////////////////////////////////////////////////////////////////////
    // CRC calculation functions
    ///////////////////////////////////////////////////////////////////////////
    function [31:0] crc_bit_update;
        input [31:0] crc;
        input data_bit;
        begin
            crc_bit_update = (crc << 1) ^ ((crc[31] ^ data_bit) ? CRC32_POLY : 32'h0);
        end
    endfunction
    
    // CRC calculation for current data byte
    function [31:0] crc_byte_update;
        input [31:0] crc_in;
        input [7:0] data;
        reg [31:0] crc_temp;
        integer i;
        begin
            crc_temp = crc_in;
            for (i = 7; i >= 0; i = i - 1) begin
                crc_temp = crc_bit_update(crc_temp, data[i]);
            end
            crc_byte_update = crc_temp;
        end
    endfunction
    
    // Calculate next CRC value based on current data
    assign crc_update = crc_byte_update(crc, tx_data);
    
    // CRC update logic
    always @(*) begin
        if (state == IDLE || state == FCS || state == HOLD) begin
            crc_next = crc;
        end else if (state == PREAMBLE && byte_cnt == 7) begin
            crc_next = 32'hFFFFFFFF; // Reset CRC when moving to MAC_HEADER
        end else begin
            crc_next = crc_update;
        end
    end
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst) begin
            crc <= 32'hFFFFFFFF;
        end else begin
            crc <= crc_next;
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Output Register Module
///////////////////////////////////////////////////////////////////////////////
module pause_frame_output_reg (
    input wire clk,
    input wire rst,
    input wire [7:0] tx_data_in,
    input wire tx_valid_in,
    input wire tx_enable_in,
    output reg [7:0] tx_data_out,
    output reg tx_valid_out,
    output reg tx_enable_out
);
    // Sequential logic for output registers
    always @(posedge clk) begin
        if (rst) begin
            tx_data_out <= 8'h0;
            tx_valid_out <= 1'b0;
            tx_enable_out <= 1'b0;
        end else begin
            tx_data_out <= tx_data_in;
            tx_valid_out <= tx_valid_in;
            tx_enable_out <= tx_enable_in;
        end
    end
    
endmodule