//SystemVerilog - IEEE 1364-2005 Standard
module eth_full_duplex_controller (
    input wire clk,
    input wire rst_n,
    // MAC layer interface
    input wire tx_request,
    output wire tx_grant,
    input wire tx_complete,
    output wire rx_enable,
    // Flow control
    input wire pause_frame_rx,
    input wire [15:0] pause_quanta_rx,
    output wire pause_frame_tx,
    output wire [15:0] pause_quanta_tx,
    // Status and control
    input wire rx_buffer_almost_full,
    output wire flow_control_active
);
    // Internal connection signals
    wire pause_control_active;
    
    // Instantiate transmission control module
    tx_control_module tx_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .tx_request(tx_request),
        .tx_complete(tx_complete),
        .flow_control_active(flow_control_active),
        .tx_grant(tx_grant),
        .state_out()
    );
    
    // Instantiate reception control module
    rx_control_module rx_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .rx_enable(rx_enable)
    );
    
    // Instantiate pause frame handling module
    pause_control_module pause_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .pause_frame_rx(pause_frame_rx),
        .pause_quanta_rx(pause_quanta_rx),
        .rx_buffer_almost_full(rx_buffer_almost_full),
        .pause_frame_tx(pause_frame_tx),
        .pause_quanta_tx(pause_quanta_tx),
        .flow_control_active(flow_control_active)
    );
    
endmodule

//SystemVerilog - IEEE 1364-2005 Standard
module tx_control_module (
    input wire clk,
    input wire rst_n,
    input wire tx_request,
    input wire tx_complete,
    input wire flow_control_active,
    output reg tx_grant,
    output reg [1:0] state_out
);
    // State definitions
    localparam IDLE = 2'b00, TRANSMIT = 2'b01, PAUSE = 2'b10, WAIT_IFG = 2'b11;
    
    reg [1:0] state;
    reg [15:0] ifg_counter;
    
    localparam IFG_TIME = 16'd12; // 12 byte times for Inter-Frame Gap
    
    // Assign output state for debugging/monitoring
    always @(*) begin
        state_out = state;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_grant <= 1'b0;
            ifg_counter <= 16'd0;
        end else begin
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
                    if (!flow_control_active) begin
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
                
                default: begin
                    state <= IDLE;
                end
            endcase
            
            // Handle flow control activation during transmission
            if (flow_control_active && (state == IDLE || state == TRANSMIT)) begin
                tx_grant <= 1'b0;
                state <= PAUSE;
            end
        end
    end
endmodule

//SystemVerilog - IEEE 1364-2005 Standard
module rx_control_module (
    input wire clk,
    input wire rst_n,
    output reg rx_enable
);
    // In full-duplex mode, rx is always enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_enable <= 1'b1;
        end else begin
            rx_enable <= 1'b1;
        end
    end
endmodule

//SystemVerilog - IEEE 1364-2005 Standard
module pause_control_module (
    input wire clk,
    input wire rst_n,
    input wire pause_frame_rx,
    input wire [15:0] pause_quanta_rx,
    input wire rx_buffer_almost_full,
    output reg pause_frame_tx,
    output reg [15:0] pause_quanta_tx,
    output reg flow_control_active
);
    reg [15:0] pause_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pause_frame_tx <= 1'b0;
            pause_quanta_tx <= 16'd0;
            flow_control_active <= 1'b0;
            pause_counter <= 16'd0;
        end else begin
            // Process received pause frames
            if (pause_frame_rx && pause_quanta_rx > 0) begin
                pause_counter <= pause_quanta_rx;
                flow_control_active <= 1'b1;
            end else if (pause_counter > 0) begin
                pause_counter <= pause_counter - 1'b1;
            end else if (pause_counter == 0 && flow_control_active) begin
                flow_control_active <= 1'b0;
            end
            
            // Generate pause frames based on buffer status
            if (rx_buffer_almost_full && !pause_frame_tx) begin
                pause_frame_tx <= 1'b1;
                pause_quanta_tx <= 16'hFFFF; // Request max pause
            end else if (!rx_buffer_almost_full && pause_frame_tx) begin
                pause_frame_tx <= 1'b0;
            end
        end
    end
endmodule