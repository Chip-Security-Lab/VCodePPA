//SystemVerilog
module width_reducer #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8  // IN_WIDTH必须是OUT_WIDTH的整数倍
)(
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire [IN_WIDTH-1:0] data_in,
    output wire [OUT_WIDTH-1:0] data_out,
    output wire out_valid,
    output wire ready_for_input
);
    localparam RATIO = IN_WIDTH / OUT_WIDTH;
    localparam CNT_WIDTH = $clog2(RATIO);

    // Data buffer and segment counter
    reg [IN_WIDTH-1:0] data_buffer;
    reg [CNT_WIDTH-1:0] segment_counter_reg, segment_counter_buf1, segment_counter_buf2;

    // Output and processing signals
    reg output_valid_reg, output_valid_buf1, output_valid_buf2;
    reg is_processing_reg, is_processing_buf1;

    // FSM state definition
    typedef enum reg [1:0] {
        S_IDLE    = 2'd0,
        S_OUTPUT  = 2'd1
    } state_t;

    // State registers and buffers
    reg [1:0] current_state_reg, current_state_buf1, current_state_buf2;
    reg [1:0] next_state_reg,  next_state_buf1, next_state_buf2;

    // High-fanout control signals for data buffer shifting
    reg b0_reg, b0_buf1, b0_buf2;
    reg b1_reg, b1_buf1, b1_buf2;

    // State transition with buffering for high-fanout S_IDLE
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state_reg <= S_IDLE;
            current_state_buf1 <= S_IDLE;
            current_state_buf2 <= S_IDLE;
        end else begin
            current_state_reg <= next_state_reg;
            current_state_buf1 <= current_state_reg;
            current_state_buf2 <= current_state_buf1;
        end
    end

    // Next state logic with buffering for high-fanout next_state
    always @(*) begin
        next_state_reg = current_state_reg;
        case (current_state_reg)
            S_IDLE: begin
                if (in_valid) begin
                    next_state_reg = S_OUTPUT;
                end
            end
            S_OUTPUT: begin
                if (segment_counter_reg == RATIO-1) begin
                    next_state_reg = S_IDLE;
                end
            end
            default: next_state_reg = S_IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            next_state_buf1 <= S_IDLE;
            next_state_buf2 <= S_IDLE;
        end else begin
            next_state_buf1 <= next_state_reg;
            next_state_buf2 <= next_state_buf1;
        end
    end

    // Buffering for segment_counter (high fanout)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            segment_counter_reg <= {CNT_WIDTH{1'b0}};
            segment_counter_buf1 <= {CNT_WIDTH{1'b0}};
            segment_counter_buf2 <= {CNT_WIDTH{1'b0}};
        end else begin
            case (current_state_reg)
                S_IDLE: begin
                    segment_counter_reg <= {CNT_WIDTH{1'b0}};
                end
                S_OUTPUT: begin
                    if (segment_counter_reg < RATIO-1)
                        segment_counter_reg <= segment_counter_reg + 1'b1;
                end
                default: begin
                    segment_counter_reg <= {CNT_WIDTH{1'b0}};
                end
            endcase
            segment_counter_buf1 <= segment_counter_reg;
            segment_counter_buf2 <= segment_counter_buf1;
        end
    end

    // Buffering for output_valid (high fanout)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            output_valid_reg <= 1'b0;
            output_valid_buf1 <= 1'b0;
            output_valid_buf2 <= 1'b0;
        end else begin
            case (current_state_reg)
                S_IDLE: begin
                    output_valid_reg <= in_valid ? 1'b1 : 1'b0;
                end
                S_OUTPUT: begin
                    if (segment_counter_reg < RATIO-1)
                        output_valid_reg <= 1'b1;
                    else
                        output_valid_reg <= 1'b0;
                end
                default: begin
                    output_valid_reg <= 1'b0;
                end
            endcase
            output_valid_buf1 <= output_valid_reg;
            output_valid_buf2 <= output_valid_buf1;
        end
    end

    // Buffering for is_processing (if high fanout)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            is_processing_reg <= 1'b0;
            is_processing_buf1 <= 1'b0;
        end else begin
            case (current_state_reg)
                S_IDLE: begin
                    is_processing_reg <= in_valid ? 1'b1 : 1'b0;
                end
                S_OUTPUT: begin
                    if (segment_counter_reg < RATIO-1)
                        is_processing_reg <= 1'b1;
                    else
                        is_processing_reg <= 1'b0;
                end
                default: begin
                    is_processing_reg <= 1'b0;
                end
            endcase
            is_processing_buf1 <= is_processing_reg;
        end
    end

    // Buffering for b0, b1 (high-fanout signals, e.g., for output_valid and FSM)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            b0_reg <= 1'b0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            b1_reg <= 1'b0;
            b1_buf1 <= 1'b0;
            b1_buf2 <= 1'b0;
        end else begin
            // Example: b0 = output_valid, b1 = ready_for_input
            b0_reg <= output_valid_reg;
            b0_buf1 <= b0_reg;
            b0_buf2 <= b0_buf1;
            b1_reg <= (current_state_reg == S_IDLE);
            b1_buf1 <= b1_reg;
            b1_buf2 <= b1_buf1;
        end
    end

    // Data buffer shifting
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_buffer <= {IN_WIDTH{1'b0}};
        end else begin
            case (current_state_reg)
                S_IDLE: begin
                    if (in_valid)
                        data_buffer <= data_in;
                end
                S_OUTPUT: begin
                    if (segment_counter_reg < RATIO-1)
                        data_buffer <= data_buffer >> OUT_WIDTH;
                end
                default: begin
                    data_buffer <= {IN_WIDTH{1'b0}};
                end
            endcase
        end
    end

    assign data_out = data_buffer[OUT_WIDTH-1:0];
    assign out_valid = output_valid_buf2;
    assign ready_for_input = b1_buf2;

endmodule