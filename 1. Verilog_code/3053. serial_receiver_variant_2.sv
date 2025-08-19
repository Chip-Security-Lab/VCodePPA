//SystemVerilog
module serial_receiver(
    input wire clk, rst, rx_in,
    output reg [7:0] data_out,
    output reg valid
);
    localparam IDLE=3'd0, START=3'd1, DATA=3'd2, STOP=3'd3;
    
    // Stage 1: Input sampling and state transition with fanout buffers
    reg [2:0] state_stage1, next_state_stage1;
    reg [2:0] state_stage1_buf1, state_stage1_buf2;
    reg [2:0] next_state_stage1_buf;
    reg rx_in_stage1;
    reg valid_stage1;
    
    // Stage 2: Data collection
    reg [2:0] state_stage2;
    reg [2:0] bit_count_stage2;
    reg [7:0] shift_reg_stage2;
    reg rx_in_stage2;
    reg valid_stage2;
    
    // Stage 3: Output generation
    reg [2:0] state_stage3;
    reg [7:0] shift_reg_stage3;
    reg valid_stage3;
    
    // Stage 1 logic with fanout buffers
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= IDLE;
            state_stage1_buf1 <= IDLE;
            state_stage1_buf2 <= IDLE;
            next_state_stage1_buf <= IDLE;
            rx_in_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            state_stage1 <= next_state_stage1_buf;
            state_stage1_buf1 <= next_state_stage1_buf;
            state_stage1_buf2 <= state_stage1_buf1;
            next_state_stage1_buf <= next_state_stage1;
            rx_in_stage1 <= rx_in;
            valid_stage1 <= (state_stage1_buf2 == STOP);
        end
    end
    
    always @(*) begin
        next_state_stage1 = state_stage1;
        case (state_stage1)
            IDLE: if (!rx_in) next_state_stage1 = START;
            START: next_state_stage1 = DATA;
            DATA: if (bit_count_stage2 == 3'd7) next_state_stage1 = STOP;
            STOP: next_state_stage1 = IDLE;
        endcase
    end
    
    // Stage 2 logic
    always @(posedge clk) begin
        if (rst) begin
            state_stage2 <= IDLE;
            bit_count_stage2 <= 0;
            shift_reg_stage2 <= 0;
            rx_in_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1_buf2;
            rx_in_stage2 <= rx_in_stage1;
            valid_stage2 <= valid_stage1;
            
            if (state_stage1_buf2 == DATA) begin
                shift_reg_stage2 <= {rx_in_stage1, shift_reg_stage2[7:1]};
                bit_count_stage2 <= bit_count_stage2 + 1;
            end else if (state_stage1_buf2 == STOP) begin
                bit_count_stage2 <= 0;
            end
        end
    end
    
    // Stage 3 logic
    always @(posedge clk) begin
        if (rst) begin
            state_stage3 <= IDLE;
            shift_reg_stage3 <= 0;
            valid_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            valid_stage3 <= valid_stage2;
            
            if (state_stage2 == STOP) begin
                shift_reg_stage3 <= shift_reg_stage2;
            end
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 0;
            valid <= 0;
        end else begin
            data_out <= shift_reg_stage3;
            valid <= valid_stage3;
        end
    end
endmodule