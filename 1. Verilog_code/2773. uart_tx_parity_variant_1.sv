//SystemVerilog

module uart_tx_parity #(parameter DWIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire tx_en,
    input wire [DWIDTH-1:0] data_in,
    input wire [1:0] parity_mode, // 00:none, 01:odd, 10:even
    output reg tx_out,
    output reg tx_active
);

    localparam IDLE = 3'd0, START_BIT = 3'd1, DATA_BITS = 3'd2, PARITY_BIT = 3'd3, STOP_BIT = 3'd4;

    // Stage 1: Control and input latching
    reg [2:0] state_stage1;
    reg tx_en_stage1;
    reg [DWIDTH-1:0] data_in_stage1;
    reg [1:0] parity_mode_stage1;

    // Stage 2: Data and parity calculation
    reg [2:0] state_stage2;
    reg tx_en_stage2;
    reg [DWIDTH-1:0] data_in_stage2;
    reg [1:0] parity_mode_stage2;
    reg [DWIDTH-1:0] data_reg_stage2;
    reg parity_stage2;
    reg tx_active_stage2;

    // Stage 3: Bit index and shift register
    reg [2:0] state_stage3;
    reg [DWIDTH-1:0] data_reg_stage3;
    reg [3:0] bit_index_stage3;
    reg [1:0] parity_mode_stage3;
    reg parity_stage3;
    reg tx_active_stage3;

    // Stage 4: Output register
    reg [2:0] state_stage4;
    reg tx_out_stage4;
    reg tx_active_stage4;

    // Bit index next computation
    wire [3:0] bit_index_next_stage3;
    wire borrow_out_stage3;

    borrow_subtractor_4bit u_borrow_subtractor_4bit (
        .minuend(bit_index_stage3),
        .subtrahend(4'd7),
        .diff(bit_index_next_stage3),
        .borrow_out(borrow_out_stage3)
    );

    // Stage 1: Latch input and state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            tx_en_stage1 <= 1'b0;
            data_in_stage1 <= {DWIDTH{1'b0}};
            parity_mode_stage1 <= 2'b00;
        end else begin
            state_stage1 <= state_stage4;
            tx_en_stage1 <= tx_en;
            data_in_stage1 <= data_in;
            parity_mode_stage1 <= parity_mode;
        end
    end

    // Stage 2: Data register and parity calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            tx_en_stage2 <= 1'b0;
            data_in_stage2 <= {DWIDTH{1'b0}};
            parity_mode_stage2 <= 2'b00;
            data_reg_stage2 <= {DWIDTH{1'b0}};
            parity_stage2 <= 1'b0;
            tx_active_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            tx_en_stage2 <= tx_en_stage1;
            data_in_stage2 <= data_in_stage1;
            parity_mode_stage2 <= parity_mode_stage1;
            if (state_stage1 == IDLE && tx_en_stage1) begin
                data_reg_stage2 <= data_in_stage1;
                parity_stage2 <= ^data_in_stage1 ^ parity_mode_stage1[0];
                tx_active_stage2 <= 1'b1;
            end else if (state_stage1 == STOP_BIT) begin
                tx_active_stage2 <= 1'b0;
            end else begin
                data_reg_stage2 <= data_reg_stage2;
                parity_stage2 <= parity_stage2;
                tx_active_stage2 <= tx_active_stage2;
            end
        end
    end

    // Stage 3: Bit index and shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            data_reg_stage3 <= {DWIDTH{1'b0}};
            bit_index_stage3 <= 4'd0;
            parity_mode_stage3 <= 2'b00;
            parity_stage3 <= 1'b0;
            tx_active_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            parity_mode_stage3 <= parity_mode_stage2;
            parity_stage3 <= parity_stage2;
            tx_active_stage3 <= tx_active_stage2;
            if (state_stage2 == START_BIT) begin
                data_reg_stage3 <= data_reg_stage2;
                bit_index_stage3 <= 4'd0;
            end else if (state_stage2 == DATA_BITS) begin
                data_reg_stage3 <= {1'b0, data_reg_stage3[DWIDTH-1:1]};
                if (!borrow_out_stage3) begin
                    bit_index_stage3 <= bit_index_stage3 + 1'b1;
                end
            end else if (state_stage2 == IDLE && tx_en_stage2) begin
                data_reg_stage3 <= data_reg_stage2;
                bit_index_stage3 <= 4'd0;
            end
        end
    end

    // Stage 4: Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4 <= IDLE;
            tx_out_stage4 <= 1'b1;
            tx_active_stage4 <= 1'b0;
        end else begin
            state_stage4 <= state_stage3;
            tx_active_stage4 <= tx_active_stage3;
            case (state_stage3)
                IDLE: begin
                    tx_out_stage4 <= 1'b1;
                end
                START_BIT: begin
                    tx_out_stage4 <= 1'b0;
                end
                DATA_BITS: begin
                    tx_out_stage4 <= data_reg_stage3[0];
                end
                PARITY_BIT: begin
                    tx_out_stage4 <= parity_stage3;
                end
                STOP_BIT: begin
                    tx_out_stage4 <= 1'b1;
                end
                default: begin
                    tx_out_stage4 <= 1'b1;
                end
            endcase
        end
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_out <= 1'b1;
            tx_active <= 1'b0;
        end else begin
            tx_out <= tx_out_stage4;
            tx_active <= tx_active_stage4;
        end
    end

endmodule

module borrow_subtractor_4bit (
    input  wire [3:0] minuend,
    input  wire [3:0] subtrahend,
    output wire [3:0] diff,
    output wire borrow_out
);
    wire [3:0] borrow;
    assign {borrow_out, diff} = borrow_subtract(minuend, subtrahend);

    function [4:0] borrow_subtract;
        input [3:0] a, b;
        integer i;
        reg [3:0] d;
        reg [4:0] br;
        begin
            br[0] = 1'b0;
            for (i = 0; i < 4; i = i + 1) begin
                d[i] = a[i] ^ b[i] ^ br[i];
                br[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & br[i]);
            end
            borrow_subtract = {br[4], d};
        end
    endfunction
endmodule