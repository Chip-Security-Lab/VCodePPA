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
    localparam IDLE = 2'b00, TRANSMIT = 2'b01, PAUSE = 2'b10, WAIT_IFG = 2'b11;
    
    reg [1:0] state;
    reg [15:0] pause_counter;
    reg [15:0] ifg_counter;
    
    localparam IFG_TIME = 16'd12; // 12 byte times for Inter-Frame Gap
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_grant <= 1'b0;
            rx_enable <= 1'b1; // Always enabled in full-duplex
            pause_frame_tx <= 1'b0;
            pause_quanta_tx <= 16'd0;
            flow_control_active <= 1'b0;
            pause_counter <= 16'd0;
            ifg_counter <= 16'd0;
        end else begin
            // Handle received pause frames
            if (pause_frame_rx && pause_quanta_rx > 0) begin
                pause_counter <= pause_quanta_rx;
                flow_control_active <= 1'b1;
                if (state == TRANSMIT) begin
                    // Continue current transmission but don't start new ones
                    state <= PAUSE;
                end else if (state == IDLE) begin
                    state <= PAUSE;
                    tx_grant <= 1'b0;
                end
            end
            
            // Generate pause frames when receive buffer is almost full
            if (rx_buffer_almost_full && !pause_frame_tx) begin
                pause_frame_tx <= 1'b1;
                pause_quanta_tx <= 16'hFFFF; // Request max pause
            end else if (!rx_buffer_almost_full && pause_frame_tx) begin
                pause_frame_tx <= 1'b0;
            end
            
            case (state)
                IDLE: begin
                    if (tx_request && !flow_control_active) begin
                        tx_grant <= 1'b1;
                        state <= TRANSMIT;
                    end
                end
                
                TRANSMIT: begin
                    if (tx_complete) begin
                        tx_grant <= 1'b0;
                        state <= WAIT_IFG;
                        ifg_counter <= IFG_TIME;
                    end
                end
                
                PAUSE: begin
                    tx_grant <= 1'b0;
                    
                    if (pause_counter > 0) begin
                        pause_counter <= pause_counter - 1'b1;
                    end else begin
                        flow_control_active <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                WAIT_IFG: begin
                    if (ifg_counter > 0) begin
                        ifg_counter <= ifg_counter - 1'b1;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule