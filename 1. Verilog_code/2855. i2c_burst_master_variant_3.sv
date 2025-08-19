//SystemVerilog
module i2c_burst_master(
    input              clk,
    input              rstn,
    input              start,
    input      [6:0]   dev_addr,
    input      [7:0]   mem_addr,
    input      [7:0]   wdata [0:3],
    input      [1:0]   byte_count,
    output reg [7:0]   rdata [0:3],
    output reg         busy,
    output reg         done,
    inout              scl,
    inout              sda
);

// State encoding
localparam IDLE              = 4'h0;
localparam START_CONDITION   = 4'h1;
localparam SEND_DEV_ADDR     = 4'h2;
localparam SEND_MEM_ADDR     = 4'h3;
localparam WRITE_DATA        = 4'h4;
localparam RESTART           = 4'h5;
localparam SEND_DEV_ADDR_RD  = 4'h6;
localparam READ_DATA         = 4'h7;
localparam STOP_CONDITION    = 4'h8;
localparam DONE_STATE        = 4'h9;

// Pipeline stage registers
reg [3:0]   curr_state, next_state;
reg [2:0]   bit_cnt_stage1, bit_cnt_stage2;
reg [1:0]   byte_idx_stage1, byte_idx_stage2;
reg [7:0]   tx_data_stage1, tx_data_stage2;
reg [7:0]   rx_data_stage1, rx_data_stage2;
reg         scl_oe_stage1, scl_oe_stage2;
reg         sda_oe_stage1, sda_oe_stage2;
reg         sda_out_stage1, sda_out_stage2;
reg         ack_stage1, ack_stage2;
reg [7:0]   rdata_internal [0:3];

// Parallel prefix subtractor instance signals
wire [7:0]   pps_a;
wire [7:0]   pps_b;
wire         pps_bin;
wire [7:0]   pps_diff;
wire         pps_bout;

// Subtraction control signals
reg [7:0]    subtractor_a;
reg [7:0]    subtractor_b;
reg          subtractor_bin;
reg [7:0]    subtractor_result;
reg          subtractor_borrow;

// Main state register
always @(posedge clk or negedge rstn) begin
    if (!rstn)
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

// Busy signal
always @(posedge clk or negedge rstn) begin
    if (!rstn)
        busy <= 1'b0;
    else if (curr_state == IDLE && start)
        busy <= 1'b1;
    else if (curr_state == DONE_STATE)
        busy <= 1'b0;
end

// Done signal
always @(posedge clk or negedge rstn) begin
    if (!rstn)
        done <= 1'b0;
    else if (curr_state == DONE_STATE)
        done <= 1'b1;
    else
        done <= 1'b0;
end

// Pipeline Stage 1: State decode and data selection
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bit_cnt_stage1   <= 3'd0;
        byte_idx_stage1  <= 2'd0;
        tx_data_stage1   <= 8'd0;
        scl_oe_stage1    <= 1'b0;
        sda_oe_stage1    <= 1'b0;
        sda_out_stage1   <= 1'b1;
        ack_stage1       <= 1'b0;
        subtractor_a     <= 8'd0;
        subtractor_b     <= 8'd0;
        subtractor_bin   <= 1'b0;
    end else begin
        case (curr_state)
            IDLE: begin
                bit_cnt_stage1   <= 3'd7;
                byte_idx_stage1  <= 2'd0;
                tx_data_stage1   <= {dev_addr, 1'b0}; // Write operation
                scl_oe_stage1    <= 1'b0;
                sda_oe_stage1    <= 1'b0;
                sda_out_stage1   <= 1'b1;
                ack_stage1       <= 1'b0;
                subtractor_a     <= 8'd0;
                subtractor_b     <= 8'd0;
                subtractor_bin   <= 1'b0;
            end
            START_CONDITION: begin
                scl_oe_stage1    <= 1'b0;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= 1'b0; // Start
            end
            SEND_DEV_ADDR: begin
                tx_data_stage1   <= {dev_addr, 1'b0};
                bit_cnt_stage1   <= 3'd7;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= tx_data_stage2[7];
            end
            SEND_MEM_ADDR: begin
                tx_data_stage1   <= mem_addr;
                bit_cnt_stage1   <= 3'd7;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= tx_data_stage2[7];
            end
            WRITE_DATA: begin
                tx_data_stage1   <= wdata[byte_idx_stage2];
                bit_cnt_stage1   <= 3'd7;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= tx_data_stage2[7];
            end
            RESTART: begin
                scl_oe_stage1    <= 1'b0;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= 1'b1;
            end
            SEND_DEV_ADDR_RD: begin
                tx_data_stage1   <= {dev_addr, 1'b1}; // Read operation
                bit_cnt_stage1   <= 3'd7;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= tx_data_stage2[7];
            end
            READ_DATA: begin
                sda_oe_stage1    <= 1'b0; // release line for input
                // Example usage: perform subtraction using parallel prefix subtractor
                subtractor_a     <= rx_data_stage2;
                subtractor_b     <= tx_data_stage2;
                subtractor_bin   <= 1'b0;
            end
            STOP_CONDITION: begin
                scl_oe_stage1    <= 1'b0;
                sda_oe_stage1    <= 1'b1;
                sda_out_stage1   <= 1'b1; // Stop
            end
            default: ;
        endcase
    end
end

// Pipeline Stage 2: Shift and ACK management
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bit_cnt_stage2   <= 3'd0;
        byte_idx_stage2  <= 2'd0;
        tx_data_stage2   <= 8'd0;
        rx_data_stage2   <= 8'd0;
        scl_oe_stage2    <= 1'b0;
        sda_oe_stage2    <= 1'b0;
        sda_out_stage2   <= 1'b1;
        ack_stage2       <= 1'b0;
        subtractor_result<= 8'd0;
        subtractor_borrow<= 1'b0;
    end else begin
        bit_cnt_stage2   <= bit_cnt_stage1;
        byte_idx_stage2  <= byte_idx_stage1;
        tx_data_stage2   <= tx_data_stage1;
        rx_data_stage2   <= rx_data_stage1;
        scl_oe_stage2    <= scl_oe_stage1;
        sda_oe_stage2    <= sda_oe_stage1;
        sda_out_stage2   <= sda_out_stage1;
        ack_stage2       <= ack_stage1;
        subtractor_result<= pps_diff;
        subtractor_borrow<= pps_bout;
    end
end

// Output data assignment (from internal pipeline to output port)
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        rdata[0] <= 8'd0;
        rdata[1] <= 8'd0;
        rdata[2] <= 8'd0;
        rdata[3] <= 8'd0;
    end else if (curr_state == READ_DATA && bit_cnt_stage2 == 3'd0) begin
        rdata[byte_idx_stage2] <= rx_data_stage2;
    end
end

// Next state logic
always @(*) begin
    next_state = curr_state;
    case (curr_state)
        IDLE: begin
            if (start)
                next_state = START_CONDITION;
        end
        START_CONDITION: begin
            next_state = SEND_DEV_ADDR;
        end
        SEND_DEV_ADDR: begin
            if (bit_cnt_stage2 == 3'd0)
                next_state = SEND_MEM_ADDR;
        end
        SEND_MEM_ADDR: begin
            if (bit_cnt_stage2 == 3'd0)
                next_state = WRITE_DATA;
        end
        WRITE_DATA: begin
            if (bit_cnt_stage2 == 3'd0) begin
                if (byte_idx_stage2 < byte_count - 1)
                    next_state = WRITE_DATA;
                else
                    next_state = RESTART;
            end
        end
        RESTART: begin
            next_state = SEND_DEV_ADDR_RD;
        end
        SEND_DEV_ADDR_RD: begin
            if (bit_cnt_stage2 == 3'd0)
                next_state = READ_DATA;
        end
        READ_DATA: begin
            if (bit_cnt_stage2 == 3'd0) begin
                if (byte_idx_stage2 < byte_count - 1)
                    next_state = READ_DATA;
                else
                    next_state = STOP_CONDITION;
            end
        end
        STOP_CONDITION: begin
            next_state = DONE_STATE;
        end
        DONE_STATE: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

// I2C SCL/SDA output enable logic (pipeline output)
assign scl = scl_oe_stage2 ? 1'b0 : 1'bz;
assign sda = sda_oe_stage2 ? sda_out_stage2 : 1'bz;

// Parallel Prefix Subtractor Module Instantiation
assign pps_a   = subtractor_a;
assign pps_b   = subtractor_b;
assign pps_bin = subtractor_bin;

parallel_prefix_subtractor_8bit u_parallel_prefix_subtractor_8bit (
    .a      (pps_a),
    .b      (pps_b),
    .bin    (pps_bin),
    .diff   (pps_diff),
    .bout   (pps_bout)
);

endmodule

// 8-bit Parallel Prefix Subtractor (Kogge-Stone style, IEEE 1364-2005)
module parallel_prefix_subtractor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        bin,
    output [7:0] diff,
    output       bout
);

    wire [7:0] b_comp;
    wire [7:0] g;     // Generate
    wire [7:0] p;     // Propagate
    wire [7:0] c;     // Carry (borrow chain)

    // b_comp = ~b (for subtraction, a - b = a + (~b) + 1)
    assign b_comp = ~b;

    // Generate and propagate
    assign g = ~(a) & b; // Borrow generate
    assign p = ~(a ^ b); // Borrow propagate

    // Parallel prefix borrow computation (Kogge-Stone style)
    // Level 0: initial borrows
    wire [7:0] b0;
    assign b0[0] = g[0] | (p[0] & bin);
    genvar i;
    generate
        for (i=1; i<8; i=i+1) begin : gen_b0
            assign b0[i] = g[i] | (p[i] & b0[i-1]);
        end
    endgenerate

    // Final difference
    assign diff[0] = a[0] ^ b[0] ^ bin;
    assign diff[1] = a[1] ^ b[1] ^ b0[0];
    assign diff[2] = a[2] ^ b[2] ^ b0[1];
    assign diff[3] = a[3] ^ b[3] ^ b0[2];
    assign diff[4] = a[4] ^ b[4] ^ b0[3];
    assign diff[5] = a[5] ^ b[5] ^ b0[4];
    assign diff[6] = a[6] ^ b[6] ^ b0[5];
    assign diff[7] = a[7] ^ b[7] ^ b0[6];

    // Final borrow out
    assign bout = b0[7];

endmodule