//SystemVerilog
module protocol_handler(
    input wire clock, reset_n,
    input wire rx_data, rx_valid,
    output reg tx_data, tx_valid, error
);
    localparam IDLE=0, HEADER=1, PAYLOAD=2, CHECKSUM=3;
    
    // Stage 1 registers
    reg [1:0] state_stage1, next_stage1;
    reg [3:0] byte_count_stage1;
    reg [7:0] checksum_stage1;
    reg rx_data_stage1, rx_valid_stage1;
    
    // Stage 2 registers
    reg [1:0] state_stage2;
    reg [3:0] byte_count_stage2;
    reg [7:0] checksum_stage2;
    reg rx_data_stage2, rx_valid_stage2;
    
    // Stage 3 registers
    reg [1:0] state_stage3;
    reg [3:0] byte_count_stage3;
    reg [7:0] checksum_stage3;
    reg rx_data_stage3, rx_valid_stage3;
    
    // Intermediate registers for critical path cutting
    reg [1:0] next_state_pipe;
    reg [3:0] byte_count_pipe;
    reg [7:0] checksum_pipe;
    reg rx_data_pipe, rx_valid_pipe;
    reg state_idle_pipe, state_header_pipe, state_payload_pipe, state_checksum_pipe;
    reg byte_count_eq_14_pipe;
    reg checksum_match_pipe;
    
    // Stage 1: Input capture and state transition
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state_stage1 <= IDLE;
            byte_count_stage1 <= 4'd0;
            checksum_stage1 <= 8'd0;
            rx_data_stage1 <= 1'b0;
            rx_valid_stage1 <= 1'b0;
            next_state_pipe <= IDLE;
            byte_count_pipe <= 4'd0;
            checksum_pipe <= 8'd0;
            rx_data_pipe <= 1'b0;
            rx_valid_pipe <= 1'b0;
            state_idle_pipe <= 1'b0;
            state_header_pipe <= 1'b0;
            state_payload_pipe <= 1'b0;
            state_checksum_pipe <= 1'b0;
            byte_count_eq_14_pipe <= 1'b0;
            checksum_match_pipe <= 1'b0;
        end else begin
            rx_data_stage1 <= rx_data;
            rx_valid_stage1 <= rx_valid;
            state_stage1 <= next_state_pipe;
            
            // Pipeline registers for state detection
            state_idle_pipe <= (state_stage1 == IDLE);
            state_header_pipe <= (state_stage1 == HEADER);
            state_payload_pipe <= (state_stage1 == PAYLOAD);
            state_checksum_pipe <= (state_stage1 == CHECKSUM);
            
            // Pipeline register for byte count comparison
            byte_count_eq_14_pipe <= (byte_count_stage1 == 4'd14);
            
            if (rx_valid) begin
                if (state_payload_pipe) begin
                    byte_count_pipe <= byte_count_stage1 + 4'd1;
                    checksum_pipe <= checksum_stage1 ^ {7'd0, rx_data};
                end else if (state_header_pipe) begin
                    byte_count_pipe <= 4'd0;
                    checksum_pipe <= 8'd0;
                end else begin
                    byte_count_pipe <= byte_count_stage1;
                    checksum_pipe <= checksum_stage1;
                end
            end else begin
                byte_count_pipe <= byte_count_stage1;
                checksum_pipe <= checksum_stage1;
            end
            
            // Pipeline registers for next state calculation
            if (state_idle_pipe && rx_valid && rx_data)
                next_state_pipe <= HEADER;
            else if (state_header_pipe && rx_valid)
                next_state_pipe <= PAYLOAD;
            else if (state_payload_pipe && rx_valid && byte_count_eq_14_pipe)
                next_state_pipe <= CHECKSUM;
            else if (state_checksum_pipe && rx_valid)
                next_state_pipe <= IDLE;
            else
                next_state_pipe <= state_stage1;
        end
    end
    
    // Stage 2: Data processing
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state_stage2 <= IDLE;
            byte_count_stage2 <= 4'd0;
            checksum_stage2 <= 8'd0;
            rx_data_stage2 <= 1'b0;
            rx_valid_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            byte_count_stage2 <= byte_count_pipe;
            checksum_stage2 <= checksum_pipe;
            rx_data_stage2 <= rx_data_stage1;
            rx_valid_stage2 <= rx_valid_stage1;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state_stage3 <= IDLE;
            byte_count_stage3 <= 4'd0;
            checksum_stage3 <= 8'd0;
            rx_data_stage3 <= 1'b0;
            rx_valid_stage3 <= 1'b0;
            tx_data <= 1'b0;
            tx_valid <= 1'b0;
            error <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            byte_count_stage3 <= byte_count_stage2;
            checksum_stage3 <= checksum_stage2;
            rx_data_stage3 <= rx_data_stage2;
            rx_valid_stage3 <= rx_valid_stage2;
            
            tx_data <= rx_data_stage2;
            tx_valid <= (state_stage2 == PAYLOAD) ? rx_valid_stage2 : 1'b0;
            
            // Pipeline register for checksum comparison
            checksum_match_pipe <= (checksum_stage2 == {7'd0, rx_data_stage2});
            error <= (state_stage2 == CHECKSUM && rx_valid_stage2) ? 
                    !checksum_match_pipe : 1'b0;
        end
    end
endmodule