//SystemVerilog
//IEEE 1364-2005 Verilog
module i2c_multi_master #(
    parameter ARB_TIMEOUT = 1000  // Arbitration timeout cycles
)(
    input wire clk,
    input wire rst,
    input wire [7:0] tx_data,
    input wire tx_valid,          // Indicates valid data to transmit
    output reg tx_ready,          // Indicates transmitter ready for next data
    output reg [7:0] rx_data,
    output reg rx_valid,          // Indicates valid received data
    input wire rx_ready,          // Downstream module ready to accept data
    output reg bus_busy,
    inout wire sda,
    inout wire scl
);

    // Pipeline stage definitions
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam DATA_TX = 3'd2;
    localparam ACK_RX = 3'd3;
    localparam DATA_RX = 3'd4;
    localparam ACK_TX = 3'd5;
    localparam STOP = 3'd6;

    // Pipeline stage registers
    reg [2:0] stage_current, stage_next;
    reg [2:0] stage_pipe1, stage_pipe2, stage_pipe3;
    
    // Control signals
    reg sda_prev_stage1, sda_prev_stage2, sda_prev_stage3, sda_prev_stage4;
    reg scl_prev_stage1, scl_prev_stage2, scl_prev_stage3, scl_prev_stage4;
    reg [15:0] timeout_cnt_stage1, timeout_cnt_stage2, timeout_cnt_stage3, timeout_cnt_stage4;
    reg arbitration_lost_stage1, arbitration_lost_stage2, arbitration_lost_stage3, arbitration_lost_stage4;
    reg tx_oen_stage1, tx_oen_stage2, tx_oen_stage3, tx_oen_stage4;
    reg scl_oen_stage1, scl_oen_stage2, scl_oen_stage3, scl_oen_stage4;
    reg [2:0] bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3, bit_cnt_stage4;
    
    // Pipeline valid signals
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid;
    
    // Data signals
    reg [7:0] tx_data_stage1, tx_data_stage2, tx_data_stage3, tx_data_stage4;
    reg [7:0] rx_data_stage1, rx_data_stage2, rx_data_stage3, rx_data_stage4;
    
    // Bus monitoring signals
    reg bus_busy_stage1, bus_busy_stage2, bus_busy_stage3;
    reg tx_ready_stage1, tx_ready_stage2, tx_ready_stage3;
    reg rx_valid_stage1, rx_valid_stage2, rx_valid_stage3;
    
    // Pipeline stage 1: Bus signal sampling and basic state update
    always @(posedge clk) begin
        if (rst) begin
            sda_prev_stage1 <= 1'b1;
            scl_prev_stage1 <= 1'b1;
            stage1_valid <= 0;
            stage_pipe1 <= IDLE;
            stage_current <= IDLE;
        end else begin
            // Sample I2C signals
            sda_prev_stage1 <= sda;
            scl_prev_stage1 <= scl;
            
            // Initial processing of state
            stage1_valid <= 1'b1;
            stage_pipe1 <= stage_current;
            
            // Update current stage
            stage_current <= stage_next;
        end
    end
    
    // Pipeline stage 2: Arbitration and timeout counters
    always @(posedge clk) begin
        if (rst) begin
            timeout_cnt_stage1 <= 16'h0000;
            arbitration_lost_stage1 <= 0;
            stage2_valid <= 0;
            tx_data_stage1 <= 8'h00;
            bit_cnt_stage1 <= 3'b000;
        end else if (stage1_valid) begin
            stage2_valid <= 1'b1;
            
            // Forward pipeline registers
            sda_prev_stage2 <= sda_prev_stage1;
            scl_prev_stage2 <= scl_prev_stage1;
            stage_pipe2 <= stage_pipe1;
            
            // Timeout handling
            if (bus_busy) begin
                timeout_cnt_stage1 <= timeout_cnt_stage1 + 1'b1;
                if (timeout_cnt_stage1 >= ARB_TIMEOUT - 1) begin
                    timeout_cnt_stage1 <= 16'h0000;
                end
            end else begin
                timeout_cnt_stage1 <= 16'h0000;
            end
            
            // Transaction processing
            case(stage_pipe1)
                IDLE: begin
                    if (tx_valid && !bus_busy) begin
                        tx_data_stage1 <= tx_data;
                    end
                    arbitration_lost_stage1 <= 1'b0;
                    bit_cnt_stage1 <= 3'b111; // Will wrap to 0 on increment
                end
                
                START: begin
                    bit_cnt_stage1 <= 3'b000;
                end
                
                DATA_TX: begin
                    // Check for arbitration loss
                    if (tx_oen_stage1 && sda == 1'b0) begin
                        arbitration_lost_stage1 <= 1'b1;
                    end
                    
                    if (bit_cnt_stage1 != 3'b111) begin
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    end
                end
                
                ACK_RX: begin
                    rx_data_stage1[0] <= sda; // Sample ACK bit
                end
                
                default: begin
                    // Maintain previous values
                end
            endcase
        end
    end
    
    // Pipeline stage 3: Control signal generation
    always @(posedge clk) begin
        if (rst) begin
            tx_oen_stage1 <= 1'b1;
            scl_oen_stage1 <= 1'b1;
            stage3_valid <= 0;
            stage_next <= IDLE;
        end else if (stage2_valid) begin
            // Forward pipeline registers
            timeout_cnt_stage2 <= timeout_cnt_stage1;
            arbitration_lost_stage2 <= arbitration_lost_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;
            sda_prev_stage3 <= sda_prev_stage2;
            scl_prev_stage3 <= scl_prev_stage2;
            tx_data_stage2 <= tx_data_stage1;
            rx_data_stage2 <= rx_data_stage1;
            stage_pipe3 <= stage_pipe2;
            stage3_valid <= 1'b1;
            
            // Bus busy detection for next stage
            if (stage_pipe2 == START) begin
                bus_busy_stage1 <= 1'b1;
            end else if (stage_pipe2 == STOP || 
                        arbitration_lost_stage1 || 
                        timeout_cnt_stage1 >= ARB_TIMEOUT - 1) begin
                bus_busy_stage1 <= 1'b0;
            end
            
            // Control signal generation
            case(stage_pipe2)
                IDLE: begin
                    if (tx_valid && !bus_busy) begin
                        stage_next <= START;
                        tx_oen_stage1 <= 1'b0; // Drive SDA low to initiate START
                        scl_oen_stage1 <= 1'b1; // Keep SCL high initially
                    end else begin
                        stage_next <= IDLE;
                        tx_oen_stage1 <= 1'b1;
                        scl_oen_stage1 <= 1'b1;
                    end
                end
                
                START: begin
                    scl_oen_stage1 <= 1'b0; // Now drive SCL low
                    stage_next <= DATA_TX;
                end
                
                DATA_TX: begin
                    tx_oen_stage1 <= tx_data_stage1[bit_cnt_stage1] ? 1'b1 : 1'b0;
                    
                    if (arbitration_lost_stage1) begin
                        stage_next <= IDLE;
                    end else if (bit_cnt_stage1 == 3'b111) begin
                        stage_next <= ACK_RX;
                    end else begin
                        stage_next <= DATA_TX;
                    end
                end
                
                ACK_RX: begin
                    tx_oen_stage1 <= 1'b1; // Release SDA to receive ACK
                    stage_next <= STOP;
                end
                
                STOP: begin
                    tx_oen_stage1 <= 1'b0; // Drive SDA low
                    scl_oen_stage1 <= 1'b1; // Release SCL high
                    stage_next <= IDLE;
                end
                
                default: begin
                    stage_next <= IDLE;
                    tx_oen_stage1 <= 1'b1;
                    scl_oen_stage1 <= 1'b1;
                end
            endcase
        end
    end
    
    // Pipeline stage 4: Output signal generation
    always @(posedge clk) begin
        if (rst) begin
            sda_prev_stage4 <= 1'b1;
            scl_prev_stage4 <= 1'b1;
            timeout_cnt_stage4 <= 16'h0000;
            arbitration_lost_stage4 <= 0;
            stage4_valid <= 0;
            tx_oen_stage4 <= 1'b1;
            scl_oen_stage4 <= 1'b1;
            tx_oen_stage2 <= 1'b1;
            scl_oen_stage2 <= 1'b1;
            tx_oen_stage3 <= 1'b1;
            scl_oen_stage3 <= 1'b1;
            bus_busy <= 0;
            tx_ready <= 1'b1;
            rx_valid <= 1'b0;
            rx_data <= 8'h00;
            bit_cnt_stage4 <= 3'b000;
        end else if (stage3_valid) begin
            // Forward pipeline registers
            tx_oen_stage2 <= tx_oen_stage1;
            scl_oen_stage2 <= scl_oen_stage1;
            tx_oen_stage3 <= tx_oen_stage2;
            scl_oen_stage3 <= scl_oen_stage2;
            tx_oen_stage4 <= tx_oen_stage3;
            scl_oen_stage4 <= scl_oen_stage3;
            
            sda_prev_stage4 <= sda_prev_stage3;
            scl_prev_stage4 <= scl_prev_stage3;
            timeout_cnt_stage3 <= timeout_cnt_stage2;
            timeout_cnt_stage4 <= timeout_cnt_stage3;
            arbitration_lost_stage3 <= arbitration_lost_stage2;
            arbitration_lost_stage4 <= arbitration_lost_stage3;
            bit_cnt_stage3 <= bit_cnt_stage2;
            bit_cnt_stage4 <= bit_cnt_stage3;
            stage4_valid <= stage3_valid;
            tx_data_stage3 <= tx_data_stage2;
            tx_data_stage4 <= tx_data_stage3;
            rx_data_stage3 <= rx_data_stage2;
            rx_data_stage4 <= rx_data_stage3;
            
            // Bus busy propagation through pipeline
            bus_busy_stage2 <= bus_busy_stage1;
            bus_busy_stage3 <= bus_busy_stage2;
            bus_busy <= bus_busy_stage3;
            
            // TX ready signal logic
            tx_ready_stage1 <= (stage_pipe3 == IDLE) && !bus_busy_stage1;
            tx_ready_stage2 <= tx_ready_stage1;
            tx_ready_stage3 <= tx_ready_stage2;
            tx_ready <= tx_ready_stage3;
            
            // RX data handling 
            if (stage_pipe3 == ACK_RX) begin
                rx_data <= rx_data_stage2;
                rx_valid_stage1 <= 1'b1;
            end else if (rx_ready) begin
                rx_valid_stage1 <= 1'b0;
            end
            rx_valid_stage2 <= rx_valid_stage1;
            rx_valid_stage3 <= rx_valid_stage2;
            rx_valid <= rx_valid_stage3;
        end
    end
    
    // Tri-state control with bus monitoring - use stage4 values for output
    assign sda = (tx_oen_stage4) ? 1'bz : 1'b0;
    assign scl = (scl_oen_stage4) ? 1'bz : 1'b0;

endmodule