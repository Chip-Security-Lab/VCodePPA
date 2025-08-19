//SystemVerilog
module eth_full_duplex_controller (
    input wire clk,
    input wire rst_n,
    // MAC layer interface
    input wire tx_request,
    output reg tx_grant,
    input wire tx_complete,
    output reg rx_enable,
    // Flow control
    input wire pause_frame_rx,
    input wire [15:0] pause_quanta_rx,
    output reg pause_frame_tx,
    output reg [15:0] pause_quanta_tx,
    // Status and control
    input wire rx_buffer_almost_full,
    output reg flow_control_active
);
    // State definitions
    localparam IDLE = 2'b00, TRANSMIT = 2'b01, PAUSE = 2'b10, WAIT_IFG = 2'b11;
    
    // State and counter registers
    reg [1:0] state;
    reg [15:0] pause_counter;
    reg [15:0] ifg_counter;
    
    // Input registration - directly at the combinational logic input
    reg tx_complete_reg;
    reg rx_buffer_almost_full_reg;
    
    // Control signals
    wire pause_detected;
    wire pause_expire;
    wire ifg_expire;
    wire start_transmission;
    
    // Constants
    localparam IFG_TIME = 16'd12; // 12 byte times for Inter-Frame Gap
    
    // Registered inputs for optimized timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_complete_reg <= 1'b0;
            rx_buffer_almost_full_reg <= 1'b0;
        end else begin
            tx_complete_reg <= tx_complete;
            rx_buffer_almost_full_reg <= rx_buffer_almost_full;
        end
    end
    
    // Combinational logic for control signals
    assign pause_detected = pause_frame_rx && (pause_quanta_rx > 0);
    assign pause_expire = (state == PAUSE) && (pause_counter == 0);
    assign ifg_expire = (state == WAIT_IFG) && (ifg_counter == 0);
    assign start_transmission = tx_request && !flow_control_active && (state == IDLE);
    
    // State machine and processing logic - Flattened control structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pause_counter <= 16'd0;
            ifg_counter <= 16'd0;
            tx_grant <= 1'b0;
            flow_control_active <= 1'b0;
            pause_frame_tx <= 1'b0;
            pause_quanta_tx <= 16'd0;
            rx_enable <= 1'b1; // Always enabled in full-duplex
        end else begin
            // Flattened pause frame detection and handling
            if (pause_detected && state != TRANSMIT) begin
                pause_counter <= pause_quanta_rx;
                flow_control_active <= 1'b1;
                state <= PAUSE;
                tx_grant <= 1'b0;
            end else if (pause_detected && state == TRANSMIT && tx_complete_reg) begin
                pause_counter <= pause_quanta_rx;
                flow_control_active <= 1'b1;
                state <= PAUSE;
                tx_grant <= 1'b0;
            end else if (pause_detected && state == TRANSMIT && !tx_complete_reg) begin
                pause_counter <= pause_quanta_rx;
                flow_control_active <= 1'b1;
                // Stay in TRANSMIT state until tx_complete
            end
            
            // Flattened pause counter processing
            if (state == PAUSE && pause_counter > 0) begin
                pause_counter <= pause_counter - 1'b1;
            end else if (state == PAUSE && pause_counter == 0) begin
                state <= IDLE;
                flow_control_active <= 1'b0;
            end
            
            // Flattened IFG counter processing
            if (state == WAIT_IFG && ifg_counter > 0 && !pause_detected) begin
                ifg_counter <= ifg_counter - 1'b1;
            end else if (state == WAIT_IFG && ifg_counter == 0 && !pause_detected) begin
                state <= IDLE;
            end else if (state == WAIT_IFG && pause_detected) begin
                state <= PAUSE;
            end
            
            // Flattened pause frames generation logic
            if (rx_buffer_almost_full_reg && !pause_frame_tx) begin
                pause_frame_tx <= 1'b1;
                pause_quanta_tx <= 16'hFFFF; // Request max pause
            end else if (!rx_buffer_almost_full_reg && pause_frame_tx) begin
                pause_frame_tx <= 1'b0;
                pause_quanta_tx <= 16'd0;
            end
            
            // Flattened state machine transitions
            if (state == IDLE && start_transmission) begin
                state <= TRANSMIT;
                tx_grant <= 1'b1;
            end else if (state == TRANSMIT && tx_complete_reg) begin
                state <= WAIT_IFG;
                tx_grant <= 1'b0;
                ifg_counter <= IFG_TIME;
            end
        end
    end
endmodule