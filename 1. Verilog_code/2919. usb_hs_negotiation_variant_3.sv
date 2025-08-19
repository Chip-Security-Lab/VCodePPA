//SystemVerilog
module usb_hs_negotiation (
    // Clock and reset
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream input interface
    input  wire [15:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,
    
    // AXI-Stream output interface
    output wire [15:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast,
    
    // Status signals
    output reg         hs_detected,
    output reg  [2:0]  chirp_state,
    output reg  [1:0]  speed_status
);
    // Chirp state machine states
    localparam IDLE      = 3'd0;
    localparam K_CHIRP   = 3'd1;
    localparam J_DETECT  = 3'd2;
    localparam K_DETECT  = 3'd3;
    localparam HANDSHAKE = 3'd4;
    localparam COMPLETE  = 3'd5;
    
    // Speed status values
    localparam FULLSPEED = 2'd0;
    localparam HIGHSPEED = 2'd1;
    
    // Extract signals from AXI-Stream input
    wire        chirp_start = s_axis_tdata[0];
    wire        dp_in       = s_axis_tdata[1];
    wire        dm_in       = s_axis_tdata[2];
    
    // Internal output signals to map to AXI-Stream
    reg         dp_out;
    reg         dm_out;
    reg         dp_oe;
    reg         dm_oe;
    
    // Input registers for better timing
    reg         chirp_start_r;
    reg         dp_in_r;
    reg         dm_in_r;
    
    // Internal registers
    reg  [15:0] chirp_counter;
    reg  [2:0]  kj_count;
    
    // AXI-Stream handshake logic
    assign s_axis_tready = 1'b1; // Always ready to accept data
    
    // Map internal output signals to AXI-Stream output
    assign m_axis_tdata  = {8'b0, hs_detected, chirp_state, dp_oe, dm_oe, dp_out, dm_out};
    assign m_axis_tvalid = 1'b1; // Always valid when state changes
    assign m_axis_tlast  = (chirp_state == COMPLETE); // Assert tlast when negotiation completes
    
    // Combinational logic signals
    wire [15:0] next_chirp_counter;
    wire [2:0]  next_kj_count;
    wire [2:0]  next_chirp_state;
    wire [1:0]  next_speed_status;
    wire        next_hs_detected;
    wire        next_dp_out;
    wire        next_dm_out;
    wire        next_dp_oe;
    wire        next_dm_oe;
    
    // Input register logic - synchronize all inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_start_r <= 1'b0;
            dp_in_r <= 1'b0;
            dm_in_r <= 1'b0;
        end else if (s_axis_tvalid) begin
            chirp_start_r <= chirp_start;
            dp_in_r <= dp_in;
            dm_in_r <= dm_in;
        end
    end
    
    // Combinational logic - determine next state and outputs
    assign next_chirp_counter = (chirp_state == IDLE && chirp_start_r) ? 16'd0 :
                                (chirp_state == K_CHIRP) ? chirp_counter + 16'd1 :
                                (chirp_state == J_DETECT && chirp_counter >= 16'd7500) ? 16'd0 :
                                chirp_counter;
    
    assign next_kj_count = (chirp_state == K_CHIRP && chirp_counter >= 16'd7500) ? 3'd0 : kj_count;
    
    assign next_chirp_state = (!rst_n) ? IDLE :
                              (chirp_state == IDLE && chirp_start_r) ? K_CHIRP :
                              (chirp_state == K_CHIRP && chirp_counter >= 16'd7500) ? J_DETECT :
                              chirp_state;
    
    assign next_speed_status = (!rst_n) ? FULLSPEED : speed_status;
    
    assign next_hs_detected = (!rst_n) ? 1'b0 : hs_detected;
    
    assign next_dp_out = (!rst_n) ? 1'b1 :
                         (chirp_state == IDLE && chirp_start_r) ? 1'b0 :
                         (chirp_state == K_CHIRP) ? 1'b0 : 
                         dp_out;
    
    assign next_dm_out = (!rst_n) ? 1'b0 :
                         (chirp_state == IDLE && chirp_start_r) ? 1'b1 :
                         (chirp_state == K_CHIRP) ? 1'b1 : 
                         dm_out;
    
    assign next_dp_oe = (!rst_n) ? 1'b0 :
                        (chirp_state == IDLE && chirp_start_r) ? 1'b1 :
                        (chirp_state == K_CHIRP && chirp_counter >= 16'd7500) ? 1'b0 :
                        dp_oe;
    
    assign next_dm_oe = (!rst_n) ? 1'b0 :
                        (chirp_state == IDLE && chirp_start_r) ? 1'b1 :
                        (chirp_state == K_CHIRP && chirp_counter >= 16'd7500) ? 1'b0 :
                        dm_oe;
    
    // State and output registers with backpressure handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_state <= IDLE;
            speed_status <= FULLSPEED;
            hs_detected <= 1'b0;
            dp_out <= 1'b1;  // J state (fullspeed idle)
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
            chirp_counter <= 16'd0;
            kj_count <= 3'd0;
        end else if (m_axis_tready) begin
            chirp_state <= next_chirp_state;
            speed_status <= next_speed_status;
            hs_detected <= next_hs_detected;
            dp_out <= next_dp_out;
            dm_out <= next_dm_out;
            dp_oe <= next_dp_oe;
            dm_oe <= next_dm_oe;
            chirp_counter <= next_chirp_counter;
            kj_count <= next_kj_count;
        end
    end
endmodule