//SystemVerilog
//IEEE 1364-2005 Verilog
module rs232_codec #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk, rstn,
    input wire rx, tx_valid,
    input wire [7:0] tx_data,
    output reg tx, rx_valid,
    output reg [7:0] rx_data
);
    // Optimize localparam for better timing
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    // One-cold state encoding: only one bit is 0, rest are 1
    localparam IDLE = 4'b1110;  // 14
    localparam START = 4'b1101; // 13
    localparam DATA = 4'b1011;  // 11
    localparam STOP = 4'b0111;  // 7
    
    // Optimize bit width calculation for clock counters
    localparam CLK_CNT_WIDTH = $clog2(CLKS_PER_BIT);
    
    // Pipeline stage definitions for TX path - one-cold encoding
    localparam TX_STAGE1 = 4'b1110; // State detection stage
    localparam TX_STAGE2 = 4'b1101; // Data preparation stage
    localparam TX_STAGE3 = 4'b1011; // Clock counting stage
    localparam TX_STAGE4 = 4'b0111; // Output generation stage
    
    // Pipeline stage definitions for RX path - one-cold encoding
    localparam RX_STAGE1 = 4'b1110; // Input synchronization stage
    localparam RX_STAGE2 = 4'b1101; // State detection stage
    localparam RX_STAGE3 = 4'b1011; // Sampling stage
    localparam RX_STAGE4 = 4'b0111; // Output generation stage
    
    reg [3:0] tx_state, rx_state;
    reg [CLK_CNT_WIDTH-1:0] tx_clk_count, rx_clk_count;
    reg [2:0] tx_bit_idx, rx_bit_idx;
    reg [7:0] tx_shift_reg, rx_shift_reg;
    
    // Pipeline registers for TX path
    reg [3:0] tx_stage, tx_state_stage1, tx_state_stage2, tx_state_stage3;
    reg tx_valid_stage1, tx_valid_stage2;
    reg [7:0] tx_data_stage1, tx_data_stage2;
    reg [CLK_CNT_WIDTH-1:0] tx_clk_count_stage1, tx_clk_count_stage2, tx_clk_count_stage3;
    reg [2:0] tx_bit_idx_stage1, tx_bit_idx_stage2, tx_bit_idx_stage3;
    reg [7:0] tx_shift_reg_stage1, tx_shift_reg_stage2, tx_shift_reg_stage3;
    reg tx_stage1, tx_stage2, tx_stage3;
    
    // Pipeline registers for RX path
    reg [3:0] rx_stage, rx_state_stage1, rx_state_stage2, rx_state_stage3;
    reg rx_d1, rx_d2, rx_d3, rx_d4; // Extended synchronizer chain
    reg [CLK_CNT_WIDTH-1:0] rx_clk_count_stage1, rx_clk_count_stage2, rx_clk_count_stage3;
    reg [2:0] rx_bit_idx_stage1, rx_bit_idx_stage2, rx_bit_idx_stage3;
    reg [7:0] rx_shift_reg_stage1, rx_shift_reg_stage2, rx_shift_reg_stage3;
    reg rx_valid_stage1, rx_valid_stage2, rx_valid_stage3;
    reg [7:0] rx_data_stage1, rx_data_stage2, rx_data_stage3;
    
    // Pre-compute constants for clock done conditions
    wire tx_clk_done = (tx_clk_count_stage2 == CLKS_PER_BIT-1);
    wire rx_clk_done = (rx_clk_count_stage2 == CLKS_PER_BIT-1);
    wire tx_half_clk = (tx_clk_count_stage2 == CLKS_PER_BIT/2-1);
    wire rx_half_clk = (rx_clk_count_stage2 == CLKS_PER_BIT/2-1);
    
    // Pre-compute bit index conditions
    wire tx_last_bit = (tx_bit_idx_stage2 == 3'b111);
    wire rx_last_bit = (rx_bit_idx_stage2 == 3'b111);
    
    // Stage 1: Input synchronization for RX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_d1 <= 1'b1;
            rx_d2 <= 1'b1;
            rx_d3 <= 1'b1;
            rx_d4 <= 1'b1;
            rx_stage <= RX_STAGE1;
            rx_state_stage1 <= IDLE;
            rx_clk_count_stage1 <= {CLK_CNT_WIDTH{1'b0}};
            rx_bit_idx_stage1 <= 3'b000;
        end else begin
            // Input synchronization
            rx_d1 <= rx;
            rx_d2 <= rx_d1;
            rx_d3 <= rx_d2;
            rx_d4 <= rx_d3;
            
            // Pass state to next stage
            rx_state_stage1 <= rx_state;
            rx_clk_count_stage1 <= rx_clk_count;
            rx_bit_idx_stage1 <= rx_bit_idx;
            rx_shift_reg_stage1 <= rx_shift_reg;
            rx_stage <= RX_STAGE2;
        end
    end
    
    // Stage 2: State detection for RX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_state_stage2 <= IDLE;
            rx_clk_count_stage2 <= {CLK_CNT_WIDTH{1'b0}};
            rx_bit_idx_stage2 <= 3'b000;
            rx_shift_reg_stage2 <= 8'h00;
            rx_stage <= RX_STAGE2;
        end else begin
            // Pass values from previous stage
            rx_state_stage2 <= rx_state_stage1;
            rx_clk_count_stage2 <= rx_clk_count_stage1;
            rx_bit_idx_stage2 <= rx_bit_idx_stage1;
            rx_shift_reg_stage2 <= rx_shift_reg_stage1;
            rx_stage <= RX_STAGE3;
        end
    end
    
    // Stage 3: Sampling stage for RX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_state_stage3 <= IDLE;
            rx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
            rx_bit_idx_stage3 <= 3'b000;
            rx_shift_reg_stage3 <= 8'h00;
            rx_valid_stage3 <= 1'b0;
            rx_data_stage3 <= 8'h00;
            rx_stage <= RX_STAGE3;
        end else begin
            rx_valid_stage3 <= 1'b0;
            rx_state_stage3 <= rx_state_stage2;
            rx_clk_count_stage3 <= rx_clk_count_stage2;
            rx_bit_idx_stage3 <= rx_bit_idx_stage2;
            rx_shift_reg_stage3 <= rx_shift_reg_stage2;
            
            case (rx_state_stage2)
                IDLE: begin
                    if (rx_d4 == 1'b0) begin // Start bit detected
                        rx_state_stage3 <= START;
                        rx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                    end
                end
                
                START: begin
                    if (rx_half_clk) begin
                        if (rx_d4 == 1'b0) begin // Confirm start bit
                            rx_state_stage3 <= DATA;
                            rx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                            rx_bit_idx_stage3 <= 3'b000;
                        end else begin
                            rx_state_stage3 <= IDLE; // False start
                        end
                    end else begin
                        rx_clk_count_stage3 <= rx_clk_count_stage2 + 1'b1;
                    end
                end
                
                DATA: begin
                    if (rx_clk_done) begin
                        rx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                        rx_shift_reg_stage3 <= {rx_d4, rx_shift_reg_stage2[7:1]}; // Shift in MSB
                        
                        if (rx_last_bit) begin
                            rx_state_stage3 <= STOP;
                        end else begin
                            rx_bit_idx_stage3 <= rx_bit_idx_stage2 + 1'b1;
                        end
                    end else begin
                        rx_clk_count_stage3 <= rx_clk_count_stage2 + 1'b1;
                    end
                end
                
                STOP: begin
                    if (rx_clk_done) begin
                        if (rx_d4 == 1'b1) begin // Valid stop bit
                            rx_data_stage3 <= rx_shift_reg_stage2;
                            rx_valid_stage3 <= 1'b1;
                        end
                        rx_state_stage3 <= IDLE;
                        rx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                    end else begin
                        rx_clk_count_stage3 <= rx_clk_count_stage2 + 1'b1;
                    end
                end
                
                default: rx_state_stage3 <= IDLE;
            endcase
            
            rx_stage <= RX_STAGE4;
        end
    end
    
    // Stage 4: Output generation for RX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_valid <= 1'b0;
            rx_data <= 8'h00;
            rx_state <= IDLE;
            rx_clk_count <= {CLK_CNT_WIDTH{1'b0}};
            rx_bit_idx <= 3'b000;
            rx_shift_reg <= 8'h00;
        end else begin
            // Update main state registers from pipeline
            rx_state <= rx_state_stage3;
            rx_clk_count <= rx_clk_count_stage3;
            rx_bit_idx <= rx_bit_idx_stage3;
            rx_shift_reg <= rx_shift_reg_stage3;
            
            // Update output registers
            rx_valid <= rx_valid_stage3;
            if (rx_valid_stage3) begin
                rx_data <= rx_data_stage3;
            end
        end
    end
    
    // Stage 1: State detection for TX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_state_stage1 <= IDLE;
            tx_valid_stage1 <= 1'b0;
            tx_data_stage1 <= 8'h00;
            tx_clk_count_stage1 <= {CLK_CNT_WIDTH{1'b0}};
            tx_bit_idx_stage1 <= 3'b000;
            tx_shift_reg_stage1 <= 8'h00;
            tx_stage1 <= 1'b1; // Idle high
            tx_stage <= TX_STAGE1;
        end else begin
            // Capture input signals
            tx_valid_stage1 <= tx_valid;
            tx_data_stage1 <= tx_data;
            
            // Pass state to next stage
            tx_state_stage1 <= tx_state;
            tx_clk_count_stage1 <= tx_clk_count;
            tx_bit_idx_stage1 <= tx_bit_idx;
            tx_shift_reg_stage1 <= tx_shift_reg;
            tx_stage1 <= tx;
            tx_stage <= TX_STAGE2;
        end
    end
    
    // Stage 2: Data preparation for TX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_state_stage2 <= IDLE;
            tx_valid_stage2 <= 1'b0;
            tx_data_stage2 <= 8'h00;
            tx_clk_count_stage2 <= {CLK_CNT_WIDTH{1'b0}};
            tx_bit_idx_stage2 <= 3'b000;
            tx_shift_reg_stage2 <= 8'h00;
            tx_stage2 <= 1'b1; // Idle high
            tx_stage <= TX_STAGE2;
        end else begin
            // Pass values from previous stage
            tx_state_stage2 <= tx_state_stage1;
            tx_valid_stage2 <= tx_valid_stage1;
            tx_data_stage2 <= tx_data_stage1;
            tx_clk_count_stage2 <= tx_clk_count_stage1;
            tx_bit_idx_stage2 <= tx_bit_idx_stage1;
            tx_shift_reg_stage2 <= tx_shift_reg_stage1;
            tx_stage2 <= tx_stage1;
            tx_stage <= TX_STAGE3;
        end
    end
    
    // Stage 3: Clock counting and state transition for TX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_state_stage3 <= IDLE;
            tx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
            tx_bit_idx_stage3 <= 3'b000;
            tx_shift_reg_stage3 <= 8'h00;
            tx_stage3 <= 1'b1; // Idle high
            tx_stage <= TX_STAGE3;
        end else begin
            // Default assignments
            tx_state_stage3 <= tx_state_stage2;
            tx_clk_count_stage3 <= tx_clk_count_stage2;
            tx_bit_idx_stage3 <= tx_bit_idx_stage2;
            tx_shift_reg_stage3 <= tx_shift_reg_stage2;
            tx_stage3 <= tx_stage2;
            
            case (tx_state_stage2)
                IDLE: begin
                    tx_stage3 <= 1'b1; // Idle high
                    if (tx_valid_stage2) begin
                        tx_state_stage3 <= START;
                        tx_shift_reg_stage3 <= tx_data_stage2;
                        tx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                    end
                end
                
                START: begin
                    tx_stage3 <= 1'b0; // Start bit is low
                    
                    if (tx_clk_done) begin
                        tx_state_stage3 <= DATA;
                        tx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                        tx_bit_idx_stage3 <= 3'b000;
                    end else begin
                        tx_clk_count_stage3 <= tx_clk_count_stage2 + 1'b1;
                    end
                end
                
                DATA: begin
                    tx_stage3 <= tx_shift_reg_stage2[0]; // LSB first
                    
                    if (tx_clk_done) begin
                        tx_clk_count_stage3 <= {CLK_CNT_WIDTH{1'b0}};
                        tx_shift_reg_stage3 <= {1'b0, tx_shift_reg_stage2[7:1]}; // Right shift
                        
                        if (tx_last_bit) begin
                            tx_state_stage3 <= STOP;
                        end else begin
                            tx_bit_idx_stage3 <= tx_bit_idx_stage2 + 1'b1;
                        end
                    end else begin
                        tx_clk_count_stage3 <= tx_clk_count_stage2 + 1'b1;
                    end
                end
                
                STOP: begin
                    tx_stage3 <= 1'b1; // Stop bit is high
                    
                    if (tx_clk_done) begin
                        tx_state_stage3 <= IDLE;
                    end else begin
                        tx_clk_count_stage3 <= tx_clk_count_stage2 + 1'b1;
                    end
                end
                
                default: tx_state_stage3 <= IDLE;
            endcase
            
            tx_stage <= TX_STAGE4;
        end
    end
    
    // Stage 4: Output generation for TX path
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_state <= IDLE;
            tx <= 1'b1; // Idle high
            tx_clk_count <= {CLK_CNT_WIDTH{1'b0}};
            tx_bit_idx <= 3'b000;
            tx_shift_reg <= 8'h00;
        end else begin
            // Update main state registers from pipeline
            tx_state <= tx_state_stage3;
            tx_clk_count <= tx_clk_count_stage3;
            tx_bit_idx <= tx_bit_idx_stage3;
            tx_shift_reg <= tx_shift_reg_stage3;
            
            // Update output register
            tx <= tx_stage3;
        end
    end
    
endmodule