//SystemVerilog
// Top-level module for UART Codec with hierarchical structure
module uart_codec #(
    parameter DWIDTH = 8,
    parameter BAUD_DIV = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire tx_valid,
    input  wire rx_in,
    input  wire [DWIDTH-1:0] tx_data,
    output wire rx_valid,
    output wire tx_out,
    output wire [DWIDTH-1:0] rx_data
);

    // Common parameters package
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Instantiate TX module (transmitter)
    uart_tx_pipeline #(
        .DWIDTH(DWIDTH),
        .BAUD_DIV(BAUD_DIV)
    ) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_out(tx_out)
    );

    // Instantiate RX module (receiver)
    uart_rx_pipeline #(
        .DWIDTH(DWIDTH),
        .BAUD_DIV(BAUD_DIV)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(rx_in),
        .rx_valid(rx_valid),
        .rx_data(rx_data)
    );

endmodule

// UART Transmitter with pipelined architecture
module uart_tx_pipeline #(
    parameter DWIDTH = 8,
    parameter BAUD_DIV = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire tx_valid,
    input  wire [DWIDTH-1:0] tx_data,
    output reg  tx_out
);

    // State definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    // Pipeline stage definitions
    localparam STAGE_PREPARE   = 2'b00;
    localparam STAGE_TRANSMIT  = 2'b01;
    localparam STAGE_FINALIZE  = 2'b10;
    
    // Pipeline stage 1 registers
    reg [1:0] tx_state_stage1;
    reg [$clog2(DWIDTH)-1:0] tx_bit_cnt_stage1;
    reg [$clog2(BAUD_DIV)-1:0] tx_baud_cnt_stage1;
    reg [DWIDTH-1:0] tx_shift_reg_stage1;
    reg tx_valid_stage1;
    reg tx_out_stage1;
    reg [1:0] tx_pipe_stage;
    
    // Pipeline stage 2 registers
    reg [1:0] tx_state_stage2;
    reg [$clog2(DWIDTH)-1:0] tx_bit_cnt_stage2;
    reg [$clog2(BAUD_DIV)-1:0] tx_baud_cnt_stage2;
    reg [DWIDTH-1:0] tx_shift_reg_stage2;
    reg tx_valid_stage2;
    reg tx_out_stage2;
    
    // Pipeline stage 3 registers
    reg [1:0] tx_state_stage3;
    reg [$clog2(DWIDTH)-1:0] tx_bit_cnt_stage3;
    reg [$clog2(BAUD_DIV)-1:0] tx_baud_cnt_stage3;
    reg [DWIDTH-1:0] tx_shift_reg_stage3;
    reg tx_valid_stage3;
    reg tx_out_stage3;

    // First pipeline stage: Prepare and decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state_stage1 <= IDLE;
            tx_bit_cnt_stage1 <= 0;
            tx_baud_cnt_stage1 <= 0;
            tx_shift_reg_stage1 <= 0;
            tx_valid_stage1 <= 1'b0;
            tx_out_stage1 <= 1'b1;
            tx_pipe_stage <= STAGE_PREPARE;
        end else begin
            tx_valid_stage1 <= tx_valid;
            
            case (tx_pipe_stage)
                STAGE_PREPARE: begin
                    if (tx_valid && tx_state_stage1 == IDLE) begin
                        tx_state_stage1 <= START;
                        tx_shift_reg_stage1 <= tx_data;
                        tx_baud_cnt_stage1 <= 0;
                        tx_out_stage1 <= 1'b0; // Start bit
                    end else if (tx_state_stage1 == START) begin
                        if (tx_baud_cnt_stage1 == BAUD_DIV-1) begin
                            tx_state_stage1 <= DATA;
                            tx_baud_cnt_stage1 <= 0;
                            tx_bit_cnt_stage1 <= 0;
                        end else begin
                            tx_baud_cnt_stage1 <= tx_baud_cnt_stage1 + 1;
                        end
                    end
                    tx_pipe_stage <= STAGE_TRANSMIT;
                end
                
                STAGE_TRANSMIT: begin
                    if (tx_state_stage1 == DATA) begin
                        if (tx_baud_cnt_stage1 == BAUD_DIV-1) begin
                            tx_out_stage1 <= tx_shift_reg_stage1[0];
                            tx_shift_reg_stage1 <= tx_shift_reg_stage1 >> 1;
                            tx_baud_cnt_stage1 <= 0;
                            
                            if (tx_bit_cnt_stage1 == DWIDTH-1)
                                tx_state_stage1 <= STOP;
                            else
                                tx_bit_cnt_stage1 <= tx_bit_cnt_stage1 + 1;
                        end else begin
                            tx_baud_cnt_stage1 <= tx_baud_cnt_stage1 + 1;
                        end
                    end
                    tx_pipe_stage <= STAGE_FINALIZE;
                end
                
                STAGE_FINALIZE: begin
                    if (tx_state_stage1 == STOP) begin
                        tx_out_stage1 <= 1'b1; // Stop bit
                        if (tx_baud_cnt_stage1 == BAUD_DIV-1)
                            tx_state_stage1 <= IDLE;
                        else
                            tx_baud_cnt_stage1 <= tx_baud_cnt_stage1 + 1;
                    end
                    tx_pipe_stage <= STAGE_PREPARE;
                end
                
                default: tx_pipe_stage <= STAGE_PREPARE;
            endcase
        end
    end
    
    // Second pipeline stage: Data processing and state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state_stage2 <= IDLE;
            tx_bit_cnt_stage2 <= 0;
            tx_baud_cnt_stage2 <= 0;
            tx_shift_reg_stage2 <= 0;
            tx_valid_stage2 <= 1'b0;
            tx_out_stage2 <= 1'b1;
        end else begin
            tx_state_stage2 <= tx_state_stage1;
            tx_bit_cnt_stage2 <= tx_bit_cnt_stage1;
            tx_baud_cnt_stage2 <= tx_baud_cnt_stage1;
            tx_shift_reg_stage2 <= tx_shift_reg_stage1;
            tx_valid_stage2 <= tx_valid_stage1;
            tx_out_stage2 <= tx_out_stage1;
        end
    end
    
    // Third pipeline stage: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state_stage3 <= IDLE;
            tx_bit_cnt_stage3 <= 0;
            tx_baud_cnt_stage3 <= 0;
            tx_shift_reg_stage3 <= 0;
            tx_valid_stage3 <= 1'b0;
            tx_out_stage3 <= 1'b1;
            tx_out <= 1'b1;
        end else begin
            tx_state_stage3 <= tx_state_stage2;
            tx_bit_cnt_stage3 <= tx_bit_cnt_stage2;
            tx_baud_cnt_stage3 <= tx_baud_cnt_stage2;
            tx_shift_reg_stage3 <= tx_shift_reg_stage2;
            tx_valid_stage3 <= tx_valid_stage2;
            tx_out_stage3 <= tx_out_stage2;
            tx_out <= tx_out_stage3;
        end
    end

endmodule

// UART Receiver with pipelined architecture
module uart_rx_pipeline #(
    parameter DWIDTH = 8,
    parameter BAUD_DIV = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rx_in,
    output reg  rx_valid,
    output reg  [DWIDTH-1:0] rx_data
);

    // State definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    // First pipeline stage signals
    reg [1:0] rx_state_stage1;
    reg [$clog2(DWIDTH)-1:0] rx_bit_cnt_stage1;
    reg [$clog2(BAUD_DIV)-1:0] rx_baud_cnt_stage1;
    reg [DWIDTH-1:0] rx_shift_reg_stage1;
    reg rx_in_stage1;
    reg rx_valid_stage1;
    
    // Second pipeline stage signals
    reg [1:0] rx_state_stage2;
    reg [$clog2(DWIDTH)-1:0] rx_bit_cnt_stage2;
    reg [$clog2(BAUD_DIV)-1:0] rx_baud_cnt_stage2;
    reg [DWIDTH-1:0] rx_shift_reg_stage2;
    reg rx_in_stage2;
    reg rx_valid_stage2;
    
    // First pipeline stage: Input sampling and state detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state_stage1 <= IDLE;
            rx_bit_cnt_stage1 <= 0;
            rx_baud_cnt_stage1 <= 0;
            rx_shift_reg_stage1 <= 0;
            rx_in_stage1 <= 1'b1;
            rx_valid_stage1 <= 1'b0;
        end else begin
            rx_in_stage1 <= rx_in;
            
            case (rx_state_stage1)
                IDLE: begin
                    if (!rx_in_stage1) begin // Detect start bit
                        rx_state_stage1 <= START;
                        rx_baud_cnt_stage1 <= 0;
                    end
                end
                
                START: begin
                    if (rx_baud_cnt_stage1 == BAUD_DIV/2-1) begin // Sample in the middle of bit
                        if (!rx_in_stage1) begin // Confirm start bit
                            rx_state_stage1 <= DATA;
                            rx_baud_cnt_stage1 <= 0;
                            rx_bit_cnt_stage1 <= 0;
                        end else
                            rx_state_stage1 <= IDLE; // False start bit, return to idle
                    end else
                        rx_baud_cnt_stage1 <= rx_baud_cnt_stage1 + 1;
                end
                
                DATA: begin
                    if (rx_baud_cnt_stage1 == BAUD_DIV-1) begin
                        rx_baud_cnt_stage1 <= 0;
                        if (rx_bit_cnt_stage1 == DWIDTH-1)
                            rx_state_stage1 <= STOP;
                        else
                            rx_bit_cnt_stage1 <= rx_bit_cnt_stage1 + 1;
                    end else begin
                        if (rx_baud_cnt_stage1 == BAUD_DIV/2-1) // Sample in the middle of bit
                            rx_shift_reg_stage1 <= {rx_in_stage1, rx_shift_reg_stage1[DWIDTH-1:1]};
                        rx_baud_cnt_stage1 <= rx_baud_cnt_stage1 + 1;
                    end
                end
                
                STOP: begin
                    if (rx_baud_cnt_stage1 == BAUD_DIV/2-1) begin
                        if (rx_in_stage1) begin // Confirm stop bit
                            rx_valid_stage1 <= 1'b1;
                        end
                    end else if (rx_baud_cnt_stage1 == BAUD_DIV-1) begin
                        rx_state_stage1 <= IDLE;
                        rx_baud_cnt_stage1 <= 0;
                        rx_valid_stage1 <= 1'b0;
                    end else
                        rx_baud_cnt_stage1 <= rx_baud_cnt_stage1 + 1;
                end
                
                default: rx_state_stage1 <= IDLE;
            endcase
        end
    end
    
    // Second pipeline stage: Data processing and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state_stage2 <= IDLE;
            rx_bit_cnt_stage2 <= 0;
            rx_baud_cnt_stage2 <= 0;
            rx_shift_reg_stage2 <= 0;
            rx_in_stage2 <= 1'b1;
            rx_valid_stage2 <= 1'b0;
            rx_valid <= 1'b0;
            rx_data <= 0;
        end else begin
            rx_state_stage2 <= rx_state_stage1;
            rx_bit_cnt_stage2 <= rx_bit_cnt_stage1;
            rx_baud_cnt_stage2 <= rx_baud_cnt_stage1;
            rx_shift_reg_stage2 <= rx_shift_reg_stage1;
            rx_in_stage2 <= rx_in_stage1;
            rx_valid_stage2 <= rx_valid_stage1;
            
            // Output control
            rx_valid <= rx_valid_stage2;
            if (rx_valid_stage2)
                rx_data <= rx_shift_reg_stage2;
        end
    end

endmodule