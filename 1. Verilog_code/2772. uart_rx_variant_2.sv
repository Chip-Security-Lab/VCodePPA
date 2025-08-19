//SystemVerilog
module uart_rx #(parameter DWIDTH = 8, SBIT = 1) (
    input wire clk,
    input wire rst_n,
    input wire rx_line,
    output reg rx_ready,
    output reg [DWIDTH-1:0] rx_data,
    output reg frame_err
);

    // State encoding
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    // Pipeline registers for each stage
    reg [1:0] state_stage1, state_stage2, state_stage3;
    reg [3:0] bit_count_stage1, bit_count_stage2, bit_count_stage3;
    reg [4:0] clk_count_stage1, clk_count_stage2, clk_count_stage3;
    reg [DWIDTH-1:0] rx_data_stage1, rx_data_stage2, rx_data_stage3;
    reg rx_ready_stage1, rx_ready_stage2, rx_ready_stage3;
    reg frame_err_stage1, frame_err_stage2, frame_err_stage3;
    reg rx_line_stage1, rx_line_stage2, rx_line_stage3;

    // Next-state signals for each stage
    reg [1:0] next_state_stage1, next_state_stage2, next_state_stage3;
    reg [3:0] next_bit_count_stage1, next_bit_count_stage2, next_bit_count_stage3;
    reg [4:0] next_clk_count_stage1, next_clk_count_stage2, next_clk_count_stage3;
    reg [DWIDTH-1:0] next_rx_data_stage1, next_rx_data_stage2, next_rx_data_stage3;
    reg next_rx_ready_stage1, next_rx_ready_stage2, next_rx_ready_stage3;
    reg next_frame_err_stage1, next_frame_err_stage2, next_frame_err_stage3;
    reg next_rx_line_stage1, next_rx_line_stage2, next_rx_line_stage3;

    // Stage 1: State, input sampling, and simple control
    always @(*) begin
        // Default assignments
        next_state_stage1 = state_stage1;
        next_clk_count_stage1 = clk_count_stage1;
        next_bit_count_stage1 = bit_count_stage1;
        next_rx_data_stage1 = rx_data_stage1;
        next_rx_ready_stage1 = 1'b0;
        next_frame_err_stage1 = 1'b0;
        next_rx_line_stage1 = rx_line;

        case (state_stage1)
            IDLE: begin
                next_rx_ready_stage1 = 1'b0;
                next_frame_err_stage1 = 1'b0;
                next_rx_data_stage1 = rx_data_stage1;
                next_bit_count_stage1 = 0;
                next_clk_count_stage1 = 0;
                if (!rx_line) begin
                    next_state_stage1 = START;
                    next_clk_count_stage1 = 0;
                end
            end
            START: begin
                next_rx_ready_stage1 = 1'b0;
                next_frame_err_stage1 = 1'b0;
                next_clk_count_stage1 = clk_count_stage1 + 1;
                next_bit_count_stage1 = 0;
                next_rx_data_stage1 = rx_data_stage1;
                if (clk_count_stage1 == 3'd7) begin
                    next_state_stage1 = DATA;
                    next_clk_count_stage1 = 0;
                end
            end
            DATA: begin
                next_rx_ready_stage1 = 1'b0;
                next_frame_err_stage1 = 1'b0;
                next_clk_count_stage1 = clk_count_stage1 + 1;
                next_rx_data_stage1 = rx_data_stage1;
                next_bit_count_stage1 = bit_count_stage1;
                if (clk_count_stage1 == 4'd7) begin
                    next_clk_count_stage1 = 0;
                    next_rx_data_stage1 = {rx_line, rx_data_stage1[DWIDTH-1:1]};
                    next_bit_count_stage1 = bit_count_stage1 + 1;
                    if (bit_count_stage1 == DWIDTH-1) begin
                        next_state_stage1 = STOP;
                    end
                end
            end
            STOP: begin
                next_clk_count_stage1 = clk_count_stage1 + 1;
                next_bit_count_stage1 = bit_count_stage1;
                next_rx_data_stage1 = rx_data_stage1;
                if (clk_count_stage1 == 4'd7) begin
                    next_state_stage1 = IDLE;
                    next_rx_ready_stage1 = 1'b1;
                    next_frame_err_stage1 = !rx_line;
                end else begin
                    next_rx_ready_stage1 = 1'b0;
                    next_frame_err_stage1 = 1'b0;
                end
            end
            default: begin
                next_state_stage1 = IDLE;
                next_clk_count_stage1 = 0;
                next_bit_count_stage1 = 0;
                next_rx_data_stage1 = {DWIDTH{1'b0}};
                next_rx_ready_stage1 = 1'b0;
                next_frame_err_stage1 = 1'b0;
            end
        endcase
    end

    // Stage 1 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            clk_count_stage1 <= 0;
            bit_count_stage1 <= 0;
            rx_data_stage1 <= {DWIDTH{1'b0}};
            rx_ready_stage1 <= 1'b0;
            frame_err_stage1 <= 1'b0;
            rx_line_stage1 <= 1'b1;
        end else begin
            state_stage1 <= next_state_stage1;
            clk_count_stage1 <= next_clk_count_stage1;
            bit_count_stage1 <= next_bit_count_stage1;
            rx_data_stage1 <= next_rx_data_stage1;
            rx_ready_stage1 <= next_rx_ready_stage1;
            frame_err_stage1 <= next_frame_err_stage1;
            rx_line_stage1 <= next_rx_line_stage1;
        end
    end

    // Stage 2: Further bit/data/clk processing
    always @(*) begin
        // Default assignments
        next_state_stage2 = state_stage2;
        next_clk_count_stage2 = clk_count_stage2;
        next_bit_count_stage2 = bit_count_stage2;
        next_rx_data_stage2 = rx_data_stage2;
        next_rx_ready_stage2 = rx_ready_stage2;
        next_frame_err_stage2 = frame_err_stage2;
        next_rx_line_stage2 = rx_line_stage2;

        // Data/clk/bit propagation
        next_state_stage2 = state_stage1;
        next_clk_count_stage2 = clk_count_stage1;
        next_bit_count_stage2 = bit_count_stage1;
        next_rx_data_stage2 = rx_data_stage1;
        next_rx_ready_stage2 = rx_ready_stage1;
        next_frame_err_stage2 = frame_err_stage1;
        next_rx_line_stage2 = rx_line_stage1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            clk_count_stage2 <= 0;
            bit_count_stage2 <= 0;
            rx_data_stage2 <= {DWIDTH{1'b0}};
            rx_ready_stage2 <= 1'b0;
            frame_err_stage2 <= 1'b0;
            rx_line_stage2 <= 1'b1;
        end else begin
            state_stage2 <= next_state_stage2;
            clk_count_stage2 <= next_clk_count_stage2;
            bit_count_stage2 <= next_bit_count_stage2;
            rx_data_stage2 <= next_rx_data_stage2;
            rx_ready_stage2 <= next_rx_ready_stage2;
            frame_err_stage2 <= next_frame_err_stage2;
            rx_line_stage2 <= next_rx_line_stage2;
        end
    end

    // Stage 3: Final output stage, output registers
    always @(*) begin
        // Default assignments
        next_state_stage3 = state_stage3;
        next_clk_count_stage3 = clk_count_stage3;
        next_bit_count_stage3 = bit_count_stage3;
        next_rx_data_stage3 = rx_data_stage3;
        next_rx_ready_stage3 = rx_ready_stage3;
        next_frame_err_stage3 = frame_err_stage3;
        next_rx_line_stage3 = rx_line_stage3;

        // Output propagation
        next_state_stage3 = state_stage2;
        next_clk_count_stage3 = clk_count_stage2;
        next_bit_count_stage3 = bit_count_stage2;
        next_rx_data_stage3 = rx_data_stage2;
        next_rx_ready_stage3 = rx_ready_stage2;
        next_frame_err_stage3 = frame_err_stage2;
        next_rx_line_stage3 = rx_line_stage2;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            clk_count_stage3 <= 0;
            bit_count_stage3 <= 0;
            rx_data_stage3 <= {DWIDTH{1'b0}};
            rx_ready_stage3 <= 1'b0;
            frame_err_stage3 <= 1'b0;
            rx_line_stage3 <= 1'b1;
        end else begin
            state_stage3 <= next_state_stage3;
            clk_count_stage3 <= next_clk_count_stage3;
            bit_count_stage3 <= next_bit_count_stage3;
            rx_data_stage3 <= next_rx_data_stage3;
            rx_ready_stage3 <= next_rx_ready_stage3;
            frame_err_stage3 <= next_frame_err_stage3;
            rx_line_stage3 <= next_rx_line_stage3;
        end
    end

    // Output assignment from final pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= {DWIDTH{1'b0}};
            rx_ready <= 1'b0;
            frame_err <= 1'b0;
        end else begin
            rx_data <= rx_data_stage3;
            rx_ready <= rx_ready_stage3;
            frame_err <= frame_err_stage3;
        end
    end

endmodule