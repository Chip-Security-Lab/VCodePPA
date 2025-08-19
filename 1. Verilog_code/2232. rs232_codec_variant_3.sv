//SystemVerilog
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
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    // Pipeline control signals
    reg tx_ready_stage1, tx_ready_stage2, tx_ready_stage3;
    reg rx_detect_stage1, rx_detect_stage2, rx_detect_stage3;
    
    // Transmitter pipeline registers
    reg [1:0] tx_state_stage1, tx_state_stage2, tx_state_stage3;
    reg [$clog2(CLKS_PER_BIT)-1:0] tx_clk_count_stage1, tx_clk_count_stage2, tx_clk_count_stage3;
    reg [2:0] tx_bit_idx_stage1, tx_bit_idx_stage2, tx_bit_idx_stage3;
    reg [7:0] tx_shift_reg_stage1, tx_shift_reg_stage2, tx_shift_reg_stage3;
    reg tx_bit_stage1, tx_bit_stage2, tx_bit_stage3;
    
    // Receiver pipeline registers
    reg [1:0] rx_state_stage1, rx_state_stage2, rx_state_stage3;
    reg [$clog2(CLKS_PER_BIT)-1:0] rx_clk_count_stage1, rx_clk_count_stage2, rx_clk_count_stage3;
    reg [2:0] rx_bit_idx_stage1, rx_bit_idx_stage2, rx_bit_idx_stage3;
    reg [7:0] rx_shift_reg_stage1, rx_shift_reg_stage2, rx_shift_reg_stage3;
    
    // RX synchronizer with pipeline structure
    reg rx_d1, rx_d2, rx_d3; // Triple-flop synchronizer for better metastability handling
    
    // Pipeline stage 1: Input capture and initial state determination
    always @(posedge clk) begin
        if (!rstn) begin
            rx_d1 <= 1'b1;
            rx_d2 <= 1'b1;
            rx_d3 <= 1'b1;
            
            tx_state_stage1 <= IDLE;
            tx_clk_count_stage1 <= 0;
            tx_bit_idx_stage1 <= 0;
            tx_shift_reg_stage1 <= 8'h00;
            tx_ready_stage1 <= 1'b0;
            tx_bit_stage1 <= 1'b1;
            
            rx_state_stage1 <= IDLE;
            rx_clk_count_stage1 <= 0;
            rx_bit_idx_stage1 <= 0;
            rx_shift_reg_stage1 <= 8'h00;
            rx_detect_stage1 <= 1'b0;
        end else begin
            // RX input synchronization
            rx_d1 <= rx;
            rx_d2 <= rx_d1;
            rx_d3 <= rx_d2;
            
            // TX initial state processing
            case (tx_state_stage1)
                IDLE: begin
                    tx_bit_stage1 <= 1'b1; // Idle high
                    
                    if (tx_valid) begin
                        tx_shift_reg_stage1 <= tx_data;
                        tx_state_stage1 <= START;
                        tx_clk_count_stage1 <= 0;
                        tx_ready_stage1 <= 1'b1;
                    end else begin
                        tx_ready_stage1 <= 1'b0;
                    end
                end
                
                START: begin
                    tx_bit_stage1 <= 1'b0; // Start bit is low
                    
                    if (tx_clk_count_stage1 < CLKS_PER_BIT - 1) begin
                        tx_clk_count_stage1 <= tx_clk_count_stage1 + 1;
                        tx_ready_stage1 <= 1'b0;
                    end else begin
                        tx_clk_count_stage1 <= 0;
                        tx_state_stage1 <= DATA;
                        tx_bit_idx_stage1 <= 0;
                        tx_ready_stage1 <= 1'b1;
                    end
                end
                
                DATA: begin
                    tx_bit_stage1 <= tx_shift_reg_stage1[0];
                    
                    if (tx_clk_count_stage1 < CLKS_PER_BIT - 1) begin
                        tx_clk_count_stage1 <= tx_clk_count_stage1 + 1;
                        tx_ready_stage1 <= 1'b0;
                    end else begin
                        tx_clk_count_stage1 <= 0;
                        
                        if (tx_bit_idx_stage1 < 7) begin
                            tx_shift_reg_stage1 <= {1'b0, tx_shift_reg_stage1[7:1]};
                            tx_bit_idx_stage1 <= tx_bit_idx_stage1 + 1;
                            tx_ready_stage1 <= 1'b1;
                        end else begin
                            tx_state_stage1 <= STOP;
                            tx_ready_stage1 <= 1'b1;
                        end
                    end
                end
                
                STOP: begin
                    tx_bit_stage1 <= 1'b1; // Stop bit is high
                    
                    if (tx_clk_count_stage1 < CLKS_PER_BIT - 1) begin
                        tx_clk_count_stage1 <= tx_clk_count_stage1 + 1;
                        tx_ready_stage1 <= 1'b0;
                    end else begin
                        tx_clk_count_stage1 <= 0;
                        tx_state_stage1 <= IDLE;
                        tx_ready_stage1 <= 1'b1;
                    end
                end
            endcase
            
            // RX initial state processing
            case (rx_state_stage1)
                IDLE: begin
                    rx_clk_count_stage1 <= 0;
                    rx_bit_idx_stage1 <= 0;
                    rx_detect_stage1 <= 1'b0;
                    
                    if (rx_d3 == 1'b0) begin // Start bit detected
                        rx_state_stage1 <= START;
                    end
                end
                
                START: begin
                    if (rx_clk_count_stage1 < CLKS_PER_BIT/2 - 1) begin
                        rx_clk_count_stage1 <= rx_clk_count_stage1 + 1;
                    end else begin
                        if (rx_d3 == 1'b0) begin // Confirm start bit at middle point
                            rx_clk_count_stage1 <= 0;
                            rx_state_stage1 <= DATA;
                            rx_detect_stage1 <= 1'b1;
                        end else begin
                            rx_state_stage1 <= IDLE; // False start
                        end
                    end
                end
                
                DATA: begin
                    if (rx_clk_count_stage1 < CLKS_PER_BIT - 1) begin
                        rx_clk_count_stage1 <= rx_clk_count_stage1 + 1;
                    end else begin
                        rx_clk_count_stage1 <= 0;
                        
                        // Sample RX bit at middle point
                        rx_shift_reg_stage1 <= {rx_d3, rx_shift_reg_stage1[7:1]};
                        
                        if (rx_bit_idx_stage1 < 7) begin
                            rx_bit_idx_stage1 <= rx_bit_idx_stage1 + 1;
                        end else begin
                            rx_state_stage1 <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    if (rx_clk_count_stage1 < CLKS_PER_BIT - 1) begin
                        rx_clk_count_stage1 <= rx_clk_count_stage1 + 1;
                    end else begin
                        if (rx_d3 == 1'b1) begin // Valid stop bit
                            rx_detect_stage1 <= 1'b1;
                        end
                        rx_state_stage1 <= IDLE;
                        rx_clk_count_stage1 <= 0;
                    end
                end
            endcase
        end
    end
    
    // Pipeline stage 2: Processing and timing calculations
    always @(posedge clk) begin
        if (!rstn) begin
            tx_state_stage2 <= IDLE;
            tx_clk_count_stage2 <= 0;
            tx_bit_idx_stage2 <= 0;
            tx_shift_reg_stage2 <= 8'h00;
            tx_ready_stage2 <= 1'b0;
            tx_bit_stage2 <= 1'b1;
            
            rx_state_stage2 <= IDLE;
            rx_clk_count_stage2 <= 0;
            rx_bit_idx_stage2 <= 0;
            rx_shift_reg_stage2 <= 8'h00;
            rx_detect_stage2 <= 1'b0;
        end else begin
            // Forward pipeline registers
            tx_state_stage2 <= tx_state_stage1;
            tx_clk_count_stage2 <= tx_clk_count_stage1;
            tx_bit_idx_stage2 <= tx_bit_idx_stage1;
            tx_shift_reg_stage2 <= tx_shift_reg_stage1;
            tx_ready_stage2 <= tx_ready_stage1;
            tx_bit_stage2 <= tx_bit_stage1;
            
            rx_state_stage2 <= rx_state_stage1;
            rx_clk_count_stage2 <= rx_clk_count_stage1;
            rx_bit_idx_stage2 <= rx_bit_idx_stage1;
            rx_shift_reg_stage2 <= rx_shift_reg_stage1;
            rx_detect_stage2 <= rx_detect_stage1;
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(posedge clk) begin
        if (!rstn) begin
            tx <= 1'b1; // Default to idle high
            rx_valid <= 1'b0;
            rx_data <= 8'h00;
            
            tx_state_stage3 <= IDLE;
            tx_clk_count_stage3 <= 0;
            tx_bit_idx_stage3 <= 0;
            tx_shift_reg_stage3 <= 8'h00;
            tx_ready_stage3 <= 1'b0;
            tx_bit_stage3 <= 1'b1;
            
            rx_state_stage3 <= IDLE;
            rx_clk_count_stage3 <= 0;
            rx_bit_idx_stage3 <= 0;
            rx_shift_reg_stage3 <= 8'h00;
            rx_detect_stage3 <= 1'b0;
        end else begin
            // Forward pipeline registers
            tx_state_stage3 <= tx_state_stage2;
            tx_clk_count_stage3 <= tx_clk_count_stage2;
            tx_bit_idx_stage3 <= tx_bit_idx_stage2;
            tx_shift_reg_stage3 <= tx_shift_reg_stage2;
            tx_ready_stage3 <= tx_ready_stage2;
            tx_bit_stage3 <= tx_bit_stage2;
            
            rx_state_stage3 <= rx_state_stage2;
            rx_clk_count_stage3 <= rx_clk_count_stage2;
            rx_bit_idx_stage3 <= rx_bit_idx_stage2;
            rx_shift_reg_stage3 <= rx_shift_reg_stage2;
            rx_detect_stage3 <= rx_detect_stage2;
            
            // Generate outputs
            tx <= tx_bit_stage3;
            
            if (rx_detect_stage3 && rx_state_stage3 == IDLE && rx_state_stage2 == STOP) begin
                rx_valid <= 1'b1;
                rx_data <= rx_shift_reg_stage3;
            end else begin
                rx_valid <= 1'b0;
            end
        end
    end
endmodule