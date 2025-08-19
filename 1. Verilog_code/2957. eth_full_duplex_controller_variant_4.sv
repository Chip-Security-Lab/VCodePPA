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
    localparam IDLE = 2'b00, TRANSMIT = 2'b01, PAUSE = 2'b10, WAIT_IFG = 2'b11;
    
    reg [1:0] state, next_state;
    reg [15:0] pause_counter, next_pause_counter;
    reg [15:0] ifg_counter, next_ifg_counter;
    reg next_tx_grant, next_flow_control_active;
    reg next_pause_frame_tx;
    reg [15:0] next_pause_quanta_tx;
    
    // Registering input signals to improve timing
    reg tx_request_reg, tx_complete_reg, pause_frame_rx_reg, rx_buffer_almost_full_reg;
    reg [15:0] pause_quanta_rx_reg;
    
    // Lookahead borrow signals for subtractor
    wire [15:0] borrow;
    wire [15:0] diff_pause, diff_ifg;
    
    localparam IFG_TIME = 16'd12; // 12 byte times for Inter-Frame Gap
    
    // Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_request_reg <= 1'b0;
            tx_complete_reg <= 1'b0;
            pause_frame_rx_reg <= 1'b0;
            pause_quanta_rx_reg <= 16'd0;
            rx_buffer_almost_full_reg <= 1'b0;
        end else begin
            tx_request_reg <= tx_request;
            tx_complete_reg <= tx_complete;
            pause_frame_rx_reg <= pause_frame_rx;
            pause_quanta_rx_reg <= pause_quanta_rx;
            rx_buffer_almost_full_reg <= rx_buffer_almost_full;
        end
    end
    
    // Lookahead borrow subtractor for pause_counter
    assign borrow[0] = next_pause_counter[0] < 1'b1;
    assign diff_pause[0] = next_pause_counter[0] ^ 1'b1;
    
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : gen_borrow_pause
            assign borrow[i] = (next_pause_counter[i] < 1'b0) || 
                               ((next_pause_counter[i] == 1'b0) && borrow[i-1]);
            assign diff_pause[i] = next_pause_counter[i] ^ 1'b0 ^ borrow[i-1];
        end
    endgenerate
    
    // Lookahead borrow subtractor for ifg_counter
    wire [15:0] ifg_borrow;
    assign ifg_borrow[0] = next_ifg_counter[0] < 1'b1;
    assign diff_ifg[0] = next_ifg_counter[0] ^ 1'b1;
    
    generate
        for (i = 1; i < 16; i = i + 1) begin : gen_borrow_ifg
            assign ifg_borrow[i] = (next_ifg_counter[i] < 1'b0) || 
                                   ((next_ifg_counter[i] == 1'b0) && ifg_borrow[i-1]);
            assign diff_ifg[i] = next_ifg_counter[i] ^ 1'b0 ^ ifg_borrow[i-1];
        end
    endgenerate
    
    // Combinational next-state and output logic
    always @(*) begin
        // Default: maintain current state
        next_state = state;
        next_pause_counter = pause_counter;
        next_ifg_counter = ifg_counter;
        next_tx_grant = tx_grant;
        next_flow_control_active = flow_control_active;
        next_pause_frame_tx = pause_frame_tx;
        next_pause_quanta_tx = pause_quanta_tx;
        
        // Handle received pause frames
        if (pause_frame_rx_reg && pause_quanta_rx_reg > 0) begin
            next_pause_counter = pause_quanta_rx_reg;
            next_flow_control_active = 1'b1;
            if (state == TRANSMIT) begin
                // Continue current transmission but don't start new ones
                next_state = PAUSE;
            end else if (state == IDLE) begin
                next_state = PAUSE;
                next_tx_grant = 1'b0;
            end
        end
        
        // Generate pause frames when receive buffer is almost full
        if (rx_buffer_almost_full_reg && !pause_frame_tx) begin
            next_pause_frame_tx = 1'b1;
            next_pause_quanta_tx = 16'hFFFF; // Request max pause
        end else if (!rx_buffer_almost_full_reg && pause_frame_tx) begin
            next_pause_frame_tx = 1'b0;
        end
        
        case (state)
            IDLE: begin
                if (tx_request_reg && !flow_control_active) begin
                    next_tx_grant = 1'b1;
                    next_state = TRANSMIT;
                end
            end
            
            TRANSMIT: begin
                if (tx_complete_reg) begin
                    next_tx_grant = 1'b0;
                    next_state = WAIT_IFG;
                    next_ifg_counter = IFG_TIME;
                end
            end
            
            PAUSE: begin
                next_tx_grant = 1'b0;
                
                if (pause_counter > 0) begin
                    next_pause_counter = diff_pause; // Using lookahead borrow subtractor
                end else begin
                    next_flow_control_active = 1'b0;
                    next_state = IDLE;
                end
            end
            
            WAIT_IFG: begin
                if (ifg_counter > 0) begin
                    next_ifg_counter = diff_ifg; // Using lookahead borrow subtractor
                end else begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Sequential logic - state updates
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
            state <= next_state;
            tx_grant <= next_tx_grant;
            pause_frame_tx <= next_pause_frame_tx;
            pause_quanta_tx <= next_pause_quanta_tx;
            flow_control_active <= next_flow_control_active;
            pause_counter <= next_pause_counter;
            ifg_counter <= next_ifg_counter;
        end
    end
endmodule