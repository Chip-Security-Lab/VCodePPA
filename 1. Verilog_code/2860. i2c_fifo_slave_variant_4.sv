//SystemVerilog
module i2c_fifo_slave #(
    parameter FIFO_DEPTH = 4,
    parameter ADDR = 7'h42
)(
    input clk, rstn,
    output reg fifo_full, fifo_empty,
    output reg [7:0] data_out,
    output reg data_valid,
    inout sda, scl
);
    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_pointer, rd_pointer;
    reg [4:0] state_reg;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_index;

    // One-cold state encoding (5 states, only one bit is 0 at a time)
    localparam STATE_IDLE        = 5'b11110;
    localparam STATE_ADDR        = 5'b11101;
    localparam STATE_ACK1        = 5'b11011;
    localparam STATE_DATA        = 5'b10111;
    localparam STATE_ACK2        = 5'b01111;

    // I2C control signals
    reg sda_output, sda_oe;
    assign sda = sda_oe ? sda_output : 1'bz;

    // Start condition detection
    reg start_condition;
    reg scl_dly, sda_dly;

    always @(posedge clk) begin
        scl_dly <= scl;
        sda_dly <= sda;
        start_condition <= scl && scl_dly && !sda && sda_dly;
    end

    // Han-Carlson 8-bit adder module instantiation for pointer arithmetic
    wire [$clog2(FIFO_DEPTH):0] wr_pointer_next;
    wire [$clog2(FIFO_DEPTH):0] rd_pointer_next;
    wire [7:0] fifo_addr_diff;
    wire [7:0] wr_pointer_ext, rd_pointer_ext;
    assign wr_pointer_ext = {{(8-($clog2(FIFO_DEPTH)+1)){1'b0}}, wr_pointer};
    assign rd_pointer_ext = {{(8-($clog2(FIFO_DEPTH)+1)){1'b0}}, rd_pointer};

    han_carlson_adder_8 add_wr_ptr (
        .a(wr_pointer_ext),
        .b(8'd1),
        .cin(1'b0),
        .sum(wr_pointer_next),
        .cout()
    );
    han_carlson_adder_8 add_rd_ptr (
        .a(rd_pointer_ext),
        .b(8'd1),
        .cin(1'b0),
        .sum(rd_pointer_next),
        .cout()
    );
    han_carlson_adder_8 sub_ptr_diff (
        .a(wr_pointer_ext),
        .b(~rd_pointer_ext + 8'd1),
        .cin(1'b0),
        .sum(fifo_addr_diff),
        .cout()
    );

    // Intermediate condition signals for control flow simplification
    reg addr_match;
    reg is_last_addr_bit;
    reg is_last_data_bit;
    reg scl_high;
    reg fifo_write_enable;
    reg fifo_read_enable;

    always @(*) begin
        addr_match = (rx_shift_reg[7:1] == ADDR);
        is_last_addr_bit = (bit_index == 4'd7);
        is_last_data_bit = (bit_index == 4'd7);
        scl_high = scl;
        fifo_write_enable = (state_reg == STATE_ACK2) && (!fifo_full);
        fifo_read_enable = (!fifo_empty) && (!data_valid);
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_pointer <= 0;
            rd_pointer <= 0;
            state_reg <= STATE_IDLE;
            data_valid <= 1'b0;
            data_out <= 8'h00;
            sda_oe <= 1'b0;
            sda_output <= 1'b0;
            bit_index <= 4'd0;
            rx_shift_reg <= 8'h00;
        end else begin
            // Default assignments for combinational signals
            // (will be overwritten if state machine sets otherwise)
            case (state_reg)
                STATE_IDLE: begin
                    if (start_condition) begin
                        state_reg <= STATE_ADDR;
                        bit_index <= 4'd0;
                        rx_shift_reg <= 8'h00;
                    end
                end
                STATE_ADDR: begin
                    if (is_last_addr_bit) begin
                        if (addr_match) begin
                            state_reg <= STATE_ACK1;
                            sda_oe <= 1'b1;
                            sda_output <= 1'b0; // ACK
                        end else begin
                            state_reg <= STATE_IDLE;
                        end
                    end else begin
                        if (scl_high) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda};
                            bit_index <= bit_index + 1;
                        end
                    end
                end
                STATE_ACK1: begin
                    state_reg <= STATE_DATA;
                    bit_index <= 4'd0;
                    sda_oe <= 1'b0;
                end
                STATE_DATA: begin
                    if (is_last_data_bit) begin
                        state_reg <= STATE_ACK2;
                        sda_oe <= 1'b1;
                        sda_output <= 1'b0; // ACK
                    end else begin
                        if (scl_high) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda};
                            bit_index <= bit_index + 1;
                        end
                    end
                end
                STATE_ACK2: begin
                    state_reg <= STATE_IDLE;
                    if (fifo_write_enable) begin
                        fifo_mem[wr_pointer[$clog2(FIFO_DEPTH)-1:0]] <= rx_shift_reg;
                        wr_pointer <= wr_pointer_next[$clog2(FIFO_DEPTH):0];
                    end
                    sda_oe <= 1'b0;
                end
                default: state_reg <= STATE_IDLE;
            endcase

            // Read from FIFO
            if (fifo_read_enable) begin
                data_out <= fifo_mem[rd_pointer[$clog2(FIFO_DEPTH)-1:0]];
                rd_pointer <= rd_pointer_next[$clog2(FIFO_DEPTH):0];
                data_valid <= 1'b1;
            end else if (data_valid) begin
                data_valid <= 1'b0;
            end
        end
    end

    always @(*) begin
        fifo_full = (fifo_addr_diff == FIFO_DEPTH);
        fifo_empty = (wr_pointer == rd_pointer);
    end
endmodule

module han_carlson_adder_8 (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    wire [7:0] g, p;
    wire [7:0] x;
    wire [7:0] c;

    assign g = a & b;
    assign p = a ^ b;

    // Generate/Propagate prefix tree
    wire [7:0] G1, P1;
    wire [7:0] G2, P2;
    wire [7:0] G3, P3;
    wire [7:0] G4, P4;

    // Stage 1: (distance 1)
    assign G1[0] = g[0];
    assign P1[0] = p[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : stage1
            assign G1[i1] = g[i1] | (p[i1] & g[i1-1]);
            assign P1[i1] = p[i1] & p[i1-1];
        end
    endgenerate

    // Stage 2: (distance 2)
    assign G2[0] = G1[0];
    assign P2[0] = P1[0];
    assign G2[1] = G1[1];
    assign P2[1] = P1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : stage2
            assign G2[i2] = G1[i2] | (P1[i2] & G1[i2-2]);
            assign P2[i2] = P1[i2] & P1[i2-2];
        end
    endgenerate

    // Stage 3: (distance 4)
    assign G3[0] = G2[0];
    assign P3[0] = P2[0];
    assign G3[1] = G2[1];
    assign P3[1] = P2[1];
    assign G3[2] = G2[2];
    assign P3[2] = P2[2];
    assign G3[3] = G2[3];
    assign P3[3] = P2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : stage3
            assign G3[i3] = G2[i3] | (P2[i3] & G2[i3-4]);
            assign P3[i3] = P2[i3] & P2[i3-4];
        end
    endgenerate

    // Stage 4: Final stage (Han-Carlson: some nodes use less computation)
    assign G4[0] = G3[0];
    assign G4[1] = G3[1];
    assign G4[2] = G3[2];
    assign G4[3] = G3[3];
    assign G4[4] = G3[4];
    assign G4[5] = G3[5];
    assign G4[6] = G3[6];
    assign G4[7] = G3[7];

    // Carry chain
    assign c[0] = cin;
    assign c[1] = G1[0] | (P1[0] & cin);
    assign c[2] = G2[1] | (P2[1] & cin);
    assign c[3] = G2[2] | (P2[2] & c[1]);
    assign c[4] = G3[3] | (P3[3] & c[0]);
    assign c[5] = G3[4] | (P3[4] & c[1]);
    assign c[6] = G3[5] | (P3[5] & c[2]);
    assign c[7] = G3[6] | (P3[6] & c[3]);

    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];

    assign cout = G4[7] | (P3[7] & c[7]);
endmodule