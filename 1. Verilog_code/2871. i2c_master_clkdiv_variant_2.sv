//SystemVerilog
module i2c_master_clkdiv #(
    parameter CLK_DIV = 100,   // Clock division factor
    parameter ADDR_WIDTH = 7   // 7-bit address mode
)(
    input clk,
    input rst_n,
    input start,
    input [ADDR_WIDTH-1:0] dev_addr,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg ack_error,
    inout sda,
    inout scl
);

// Pipeline stages - One-hot encoded states (IEEE 1364-2005)
localparam STAGE_IDLE  = 6'b000001;
localparam STAGE_START = 6'b000010;
localparam STAGE_ADDR  = 6'b000100;
localparam STAGE_TX    = 6'b001000;
localparam STAGE_RX    = 6'b010000;
localparam STAGE_STOP  = 6'b100000;

// Pipeline control signals
reg [5:0] stage1_state, stage2_state, stage3_state;
reg stage1_valid, stage2_valid, stage3_valid;
reg [7:0] clk_cnt_stage1, clk_cnt_stage2, clk_cnt_stage3;
reg scl_gen_stage1, scl_gen_stage2, scl_gen_stage3;
reg sda_out_stage1, sda_out_stage2, sda_out_stage3;
reg [2:0] bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3;
reg [7:0] rx_data_stage1, rx_data_stage2, rx_data_stage3;
reg ack_error_stage1, ack_error_stage2, ack_error_stage3;
reg [ADDR_WIDTH-1:0] dev_addr_stage1, dev_addr_stage2, dev_addr_stage3;
reg [7:0] tx_data_stage1, tx_data_stage2, tx_data_stage3;

// Pipeline output selection
reg scl_out, sda_out_final;
wire sda_in;

// Tristate control
assign scl = scl_out ? 1'bz : 1'b0;
assign sda = sda_out_final ? 1'bz : 1'b0;
assign sda_in = sda;

// Pipeline stage 1: Command decode and state initialization
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_state <= STAGE_IDLE;
        stage1_valid <= 1'b0;
        clk_cnt_stage1 <= 8'h00;
        scl_gen_stage1 <= 1'b1;
        sda_out_stage1 <= 1'b1;
        bit_cnt_stage1 <= 3'b000;
        rx_data_stage1 <= 8'h00;
        ack_error_stage1 <= 1'b0;
        dev_addr_stage1 <= {ADDR_WIDTH{1'b0}};
        tx_data_stage1 <= 8'h00;
    end else begin
        case(stage1_state)
            STAGE_IDLE: begin
                if (start) begin
                    stage1_state <= STAGE_START;
                    stage1_valid <= 1'b1;
                    dev_addr_stage1 <= dev_addr;
                    tx_data_stage1 <= tx_data;
                    clk_cnt_stage1 <= 8'h00;
                end else begin
                    stage1_valid <= 1'b0;
                end
                sda_out_stage1 <= 1'b1;
                scl_gen_stage1 <= 1'b1;
            end
            STAGE_START: begin
                if (clk_cnt_stage1 == CLK_DIV/3 - 1) begin
                    clk_cnt_stage1 <= 8'h00;
                    sda_out_stage1 <= 1'b0;
                    stage1_valid <= 1'b1;
                end else begin
                    clk_cnt_stage1 <= clk_cnt_stage1 + 1'b1;
                end
            end
            default: begin
                if (stage3_valid && stage3_state == STAGE_STOP) begin
                    stage1_state <= STAGE_IDLE;
                    stage1_valid <= 1'b0;
                end
            end
        endcase
    end
end

// Pipeline stage 2: Address transmission and bit counting
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage2_state <= STAGE_IDLE;
        stage2_valid <= 1'b0;
        clk_cnt_stage2 <= 8'h00;
        scl_gen_stage2 <= 1'b1;
        sda_out_stage2 <= 1'b1;
        bit_cnt_stage2 <= 3'b000;
        rx_data_stage2 <= 8'h00;
        ack_error_stage2 <= 1'b0;
        dev_addr_stage2 <= {ADDR_WIDTH{1'b0}};
        tx_data_stage2 <= 8'h00;
    end else begin
        stage2_state <= stage1_state;
        stage2_valid <= stage1_valid;
        dev_addr_stage2 <= dev_addr_stage1;
        tx_data_stage2 <= tx_data_stage1;
        
        if (stage1_valid) begin
            case(stage1_state)
                STAGE_START: begin
                    clk_cnt_stage2 <= clk_cnt_stage1;
                    scl_gen_stage2 <= 1'b1;
                    sda_out_stage2 <= sda_out_stage1;
                    bit_cnt_stage2 <= 3'b110; // MSB first for address
                end
                STAGE_ADDR: begin
                    if (clk_cnt_stage1 == CLK_DIV/2 - 1) begin
                        scl_gen_stage2 <= 1'b0; // SCL low phase
                    end else if (clk_cnt_stage1 == CLK_DIV - 1) begin
                        scl_gen_stage2 <= 1'b1; // SCL high phase
                        if (bit_cnt_stage1 == 3'b000) begin
                            bit_cnt_stage2 <= 3'b111; // Prepare for ACK
                        end else begin
                            bit_cnt_stage2 <= bit_cnt_stage1 - 1'b1;
                        end
                        // Set SDA according to address bit
                        sda_out_stage2 <= (dev_addr_stage1[bit_cnt_stage1] == 1'b1);
                    end else begin
                        clk_cnt_stage2 <= clk_cnt_stage1 + 1'b1;
                        scl_gen_stage2 <= scl_gen_stage1;
                        sda_out_stage2 <= sda_out_stage1;
                        bit_cnt_stage2 <= bit_cnt_stage1;
                    end
                end
                default: begin
                    clk_cnt_stage2 <= clk_cnt_stage1;
                    scl_gen_stage2 <= scl_gen_stage1;
                    sda_out_stage2 <= sda_out_stage1;
                    bit_cnt_stage2 <= bit_cnt_stage1;
                end
            endcase
        end
    end
end

// Pipeline stage 3: Data transmission, reception, and completion
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage3_state <= STAGE_IDLE;
        stage3_valid <= 1'b0;
        clk_cnt_stage3 <= 8'h00;
        scl_gen_stage3 <= 1'b1;
        sda_out_stage3 <= 1'b1;
        bit_cnt_stage3 <= 3'b000;
        rx_data_stage3 <= 8'h00;
        ack_error_stage3 <= 1'b0;
        rx_data <= 8'h00;
        ack_error <= 1'b0;
        dev_addr_stage3 <= {ADDR_WIDTH{1'b0}};
        tx_data_stage3 <= 8'h00;
    end else begin
        stage3_state <= stage2_state;
        stage3_valid <= stage2_valid;
        dev_addr_stage3 <= dev_addr_stage2;
        tx_data_stage3 <= tx_data_stage2;
        
        if (stage2_valid) begin
            case(stage2_state)
                STAGE_ADDR: begin
                    clk_cnt_stage3 <= clk_cnt_stage2;
                    scl_gen_stage3 <= scl_gen_stage2;
                    sda_out_stage3 <= sda_out_stage2;
                    bit_cnt_stage3 <= bit_cnt_stage2;
                    
                    // Check for ACK after address transmission
                    if (bit_cnt_stage2 == 3'b111 && clk_cnt_stage2 == CLK_DIV/2) begin
                        ack_error_stage3 <= sda_in; // ACK is low, NACK is high
                        if (sda_in == 1'b0) begin
                            stage3_state <= (dev_addr_stage2[0]) ? STAGE_RX : STAGE_TX;
                        end else begin
                            stage3_state <= STAGE_STOP;
                        end
                    end
                end
                STAGE_TX: begin
                    if (clk_cnt_stage2 == CLK_DIV/2 - 1) begin
                        scl_gen_stage3 <= 1'b0;
                        if (bit_cnt_stage2 < 3'b111) begin
                            // Transmit data bit
                            sda_out_stage3 <= (tx_data_stage2[bit_cnt_stage2] == 1'b1);
                        end else begin
                            // Release SDA for ACK
                            sda_out_stage3 <= 1'b1;
                        end
                    end else if (clk_cnt_stage2 == CLK_DIV - 1) begin
                        scl_gen_stage3 <= 1'b1;
                        if (bit_cnt_stage2 == 3'b111) begin
                            // Check ACK
                            ack_error_stage3 <= sda_in;
                            bit_cnt_stage3 <= 3'b000;
                            stage3_state <= STAGE_STOP;
                        end else begin
                            bit_cnt_stage3 <= bit_cnt_stage2 + 1'b1;
                        end
                    end else begin
                        clk_cnt_stage3 <= clk_cnt_stage2 + 1'b1;
                        scl_gen_stage3 <= scl_gen_stage2;
                        sda_out_stage3 <= sda_out_stage2;
                        bit_cnt_stage3 <= bit_cnt_stage2;
                    end
                end
                STAGE_RX: begin
                    if (clk_cnt_stage2 == CLK_DIV/2 - 1) begin
                        scl_gen_stage3 <= 1'b0;
                    end else if (clk_cnt_stage2 == CLK_DIV*3/4 - 1) begin
                        // Sample data in the middle of SCL high
                        if (bit_cnt_stage2 < 3'b111) begin
                            rx_data_stage3[bit_cnt_stage2] <= sda_in;
                        end
                    end else if (clk_cnt_stage2 == CLK_DIV - 1) begin
                        scl_gen_stage3 <= 1'b1;
                        if (bit_cnt_stage2 == 3'b111) begin
                            // Send ACK
                            sda_out_stage3 <= 1'b0;
                            rx_data <= rx_data_stage3; // Output received data
                            stage3_state <= STAGE_STOP;
                        end else begin
                            bit_cnt_stage3 <= bit_cnt_stage2 + 1'b1;
                            sda_out_stage3 <= 1'b1; // Release SDA for next bit
                        end
                    end else begin
                        clk_cnt_stage3 <= clk_cnt_stage2 + 1'b1;
                        scl_gen_stage3 <= scl_gen_stage2;
                        sda_out_stage3 <= sda_out_stage2;
                        bit_cnt_stage3 <= bit_cnt_stage2;
                    end
                end
                STAGE_STOP: begin
                    if (clk_cnt_stage2 == CLK_DIV/3 - 1) begin
                        scl_gen_stage3 <= 1'b0;
                        sda_out_stage3 <= 1'b0;
                    end else if (clk_cnt_stage2 == CLK_DIV*2/3 - 1) begin
                        scl_gen_stage3 <= 1'b1;
                    end else if (clk_cnt_stage2 == CLK_DIV - 1) begin
                        sda_out_stage3 <= 1'b1; // Stop condition: SDA rising while SCL high
                        stage3_state <= STAGE_IDLE;
                        ack_error <= ack_error_stage3; // Update output ACK status
                    end else begin
                        clk_cnt_stage3 <= clk_cnt_stage2 + 1'b1;
                        scl_gen_stage3 <= scl_gen_stage2;
                        sda_out_stage3 <= sda_out_stage2;
                    end
                end
                default: begin
                    clk_cnt_stage3 <= clk_cnt_stage2;
                    scl_gen_stage3 <= scl_gen_stage2;
                    sda_out_stage3 <= sda_out_stage2;
                    bit_cnt_stage3 <= bit_cnt_stage2;
                end
            endcase
        end
    end
end

// Pipeline output selection logic
always @(*) begin
    if (stage3_valid) begin
        scl_out = scl_gen_stage3;
        sda_out_final = sda_out_stage3;
    end else if (stage2_valid) begin
        scl_out = scl_gen_stage2;
        sda_out_final = sda_out_stage2;
    end else if (stage1_valid) begin
        scl_out = scl_gen_stage1;
        sda_out_final = sda_out_stage1;
    end else begin
        scl_out = 1'b1;
        sda_out_final = 1'b1;
    end
end

endmodule