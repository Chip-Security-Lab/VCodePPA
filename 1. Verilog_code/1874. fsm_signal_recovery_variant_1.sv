//SystemVerilog
module fsm_signal_recovery (
    input wire clk, rst_n,
    input wire signal_detect,
    input wire [3:0] signal_value,
    output reg [3:0] recovered_value,
    output reg lock_status
);
    // Pipeline stage parameters
    localparam IDLE = 2'b00, DETECT = 2'b01, LOCK = 2'b10, TRACK = 2'b11;
    
    // Stage 1: Combinational logic control signals for next state
    wire [1:0] next_state_comb;
    reg [1:0] state_stage1;
    reg [3:0] counter_stage1;
    reg signal_detect_buf;
    reg [3:0] signal_value_buf;
    reg valid_stage1;
    
    // Stage 2: Value processing and lock determination
    reg [1:0] state_stage2;
    reg [3:0] counter_stage2;
    reg signal_detect_stage2;
    reg [3:0] signal_value_stage2;
    reg valid_stage2;
    reg [3:0] recovered_value_stage2;
    reg lock_status_stage2;
    
    // Input buffer registers - moved forward in pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_detect_buf <= 1'b0;
            signal_value_buf <= 4'd0;
        end
        else begin
            signal_detect_buf <= signal_detect;
            signal_value_buf <= signal_value;
        end
    end
    
    // Next state combinational logic - without registers
    assign next_state_comb = (state_stage1 == IDLE) ? (signal_detect_buf ? DETECT : IDLE) :
                             (state_stage1 == DETECT) ? ((counter_stage1 >= 4'd8) ? LOCK : DETECT) :
                             (state_stage1 == LOCK) ? (signal_detect_buf ? TRACK : IDLE) :
                             (state_stage1 == TRACK) ? (signal_detect_buf ? TRACK : IDLE) : IDLE;
    
    // Stage 1: State register and pipeline management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            counter_stage1 <= 4'd0;
            valid_stage1 <= 1'b0;
        end
        else begin
            state_stage1 <= next_state_comb;
            valid_stage1 <= 1'b1;
            
            case (state_stage1)
                IDLE: begin
                    counter_stage1 <= 4'd0;
                end
                DETECT: counter_stage1 <= counter_stage1 + 1'b1;
                default: counter_stage1 <= counter_stage1;
            endcase
        end
    end
    
    // Pipeline register between Stage 1 and Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            counter_stage2 <= 4'd0;
            signal_detect_stage2 <= 1'b0;
            signal_value_stage2 <= 4'd0;
            valid_stage2 <= 1'b0;
        end
        else begin
            state_stage2 <= state_stage1;
            counter_stage2 <= counter_stage1;
            signal_detect_stage2 <= signal_detect_buf;
            signal_value_stage2 <= signal_value_buf;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2: Output processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_value_stage2 <= 4'd0;
            lock_status_stage2 <= 1'b0;
        end
        else if (valid_stage2) begin
            case (state_stage2)
                IDLE: begin
                    lock_status_stage2 <= 1'b0;
                end
                LOCK: begin
                    recovered_value_stage2 <= signal_value_stage2;
                    lock_status_stage2 <= 1'b1;
                end
                TRACK: begin
                    recovered_value_stage2 <= signal_value_stage2;
                end
                default: begin
                    // Hold values
                end
            endcase
        end
    end
    
    // Final output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_value <= 4'd0;
            lock_status <= 1'b0;
        end
        else begin
            recovered_value <= recovered_value_stage2;
            lock_status <= lock_status_stage2;
        end
    end
endmodule